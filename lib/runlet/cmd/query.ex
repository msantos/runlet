defmodule Runlet.Cmd.Query do
  @moduledoc "Query a riemann server"

  defstruct url: '',
            host: '',
            port: 80,
            query: '',
            retry: 3_000,
            conn: nil,
            ref: nil,
            m: nil

  @type t :: %__MODULE__{
          url: charlist,
          host: charlist,
          port: non_neg_integer,
          query: charlist,
          retry: non_neg_integer,
          conn: pid | nil,
          ref: reference | nil,
          m: reference | nil
        }

  @riemann_url "/event/index?query="
  @riemann_host "localhost"
  @riemann_port "8080"

  defp riemann_url,
    do:
      Runlet.Config.get(:runlet, :riemann_url, @riemann_url)
      |> String.to_charlist()

  defp riemann_host,
    do:
      Runlet.Config.get(:runlet, :riemann_host, @riemann_host)
      |> String.to_charlist()

  defp riemann_port,
    do:
      Runlet.Config.get(:runlet, :riemann_port, @riemann_port)
      |> String.to_integer()

  defp riemann_event, do: Runlet.Config.get(:runlet, :riemann_event, [])

  defp riemann_retry_interval,
    do:
      Runlet.Config.get(:runlet, :riemann_retry_interval, "3000")
      |> String.to_integer()

  @doc """
  Filters events from a riemann server using the Riemann query
  language. The query must be quoted as a string:

    'state = "ok"'

  Examples of Queries:

    # Simple equality
    state = "ok"

    # Wildcards
    (service =~ "disk%") or
    (state != "critical" and host =~ "%.trioptimum.com")

    # Standard operator precedence applies
    metric_f > 2.0 and not host = nil

    # Anything with a tag "product"
    tagged "product"

    # All states
    true

  Examples from the test suite:

    https://github.com/riemann/riemann/blob/master/test/riemann/query_test.clj

  Query Grammar:

    https://github.com/riemann/riemann/blob/master/resources/query.g4
  """
  @spec exec(String.t()) :: Enumerable.t()
  def exec(q) do
    exec(q, riemann_event())
  end

  @doc false
  @spec exec(String.t(), [atom]) :: Enumerable.t()
  def exec(q, structs) do
    cfg = %Runlet.Cmd.Query{
      host: riemann_host(),
      port: riemann_port(),
      url: riemann_url(),
      retry: riemann_retry_interval(),
      query: q |> String.to_charlist()
    }

    startfun = fn ->
      {:ok, t} = open(cfg)
      t
    end

    resourcefun = fn %Runlet.Cmd.Query{conn: conn, ref: ref, m: m, retry: retry} =
                       state ->
      receive do
        {:gun_sse, ^conn, ^ref, %{event_type: "message", data: data}} ->
          case Poison.Parser.parse(data) do
            {:ok, event} ->
              e = service(event, structs)
              {[%Runlet.Event{query: q, event: e}], state}

            {:error, _} = error ->
              :error_logger.error_report([error])
              :timer.sleep(retry)
              {:ok, t} = open(state)
              {[], t}
          end

        {:gun_sse, ^conn, ^ref, _} ->
          {[], state}

        {:gun_error, ^conn, ^ref, _} ->
          :gun.close(conn)
          :timer.sleep(retry)
          {:ok, t} = open(state)
          {[], t}

        {:gun_down, _, _, _, _, _} ->
          {[], state}

        {:gun_up, _, _} ->
          {[], state}

        {:DOWN, ^m, :process, _, _} ->
          :gun.close(conn)
          :timer.sleep(retry)
          {:ok, t} = open(state)
          {[], t}

        {:runlet_stdin, stdin} ->
          {[
             %Runlet.Event{
               query: q,
               event: %Runlet.Event.Stdin{description: "#{stdin}"}
             }
           ], state}

        {:runlet_stdout, stdout} ->
          {[
             %Runlet.Event{
               query: q,
               event: %Runlet.Event.Stdout{description: "#{stdout}"}
             }
           ], state}

        {:runlet_signal, "SIGHUP"} ->
          Process.demonitor(m, [:flush])
          :gun.close(conn)
          {:ok, t} = open(state)

          {[
             %Runlet.Event{
               query: q,
               event: %Runlet.Event.Signal{description: "SIGHUP: reconnecting"}
             }
           ], t}

        {:runlet_signal, signal} ->
          {[
             %Runlet.Event{
               query: q,
               event: %Runlet.Event.Signal{description: signal}
             }
           ], state}

        :runlet_exit ->
          {:halt, state}

          #        unhandled ->
          #          :error_logger.info_report([{:unhandled_resource, unhandled}])
          #          {[], state}
      end
    end

    endfun = fn %Runlet.Cmd.Query{conn: conn} ->
      :gun.close(conn)
    end

    Stream.resource(
      startfun,
      resourcefun,
      endfun
    )
  end

  @spec open(t) :: {:ok, t}
  defp open(%Runlet.Cmd.Query{host: host, port: port, retry: retry} = state) do
    result =
      :gun.open(host, port, %{
        protocols: [:http],
        http_opts: %{content_handlers: [:gun_sse_h, :gun_data_h]},
        connect_timeout: retry,
        # retry forever
        retry: 0xFFFFFF,
        retry_timeout: retry
      })

    case result do
      {:ok, conn} ->
        m = Process.monitor(conn)

        case :gun.await_up(conn, m) do
          {:ok, :http} ->
            get(%{state | conn: conn, m: m})

          {:error, error} ->
            Process.demonitor(m, [:flush])
            :error_logger.error_report([{:gun_await_up, error}])
            :gun.close(conn)
            :timer.sleep(retry)
            open(state)
        end

      {:error, error} ->
        :error_logger.info_report([{:gun_open, error}])
        :timer.sleep(retry)
        open(state)
    end
  end

  @spec get(t) :: {:ok, t}
  defp get(
         %Runlet.Cmd.Query{
           url: url,
           query: query,
           retry: retry,
           m: m,
           conn: conn
         } = state0
       ) do
    ref =
      :gun.get(conn, [url, :http_uri.encode(query)], [
        {"accept", "text/event-stream"}
      ])

    state = %{state0 | ref: ref}

    response =
      receive do
        {:gun_response, ^conn, ^ref, :nofin, 200, _} ->
          {:ok, state}

        {:gun_response, ^conn, ^ref, :nofin, 500, _} ->
          :data_error

        {:gun_response, ^conn, ^ref, is_fin, status, headers} ->
          {:open, is_fin, status, headers}
      after
        5000 ->
          {:error, :timeout}
      end

    case response do
      {:ok, _} = n ->
        n

      {:error, _} = error ->
        Process.demonitor(m, [:flush])
        :gun.close(conn)

        :error_logger.info_report([
          error
        ])

        :timer.sleep(retry)
        open(state)

      {:open, is_fin, status, headers} ->
        Process.demonitor(m, [:flush])
        :gun.close(conn)

        :error_logger.info_report([
          {:fin, is_fin},
          {:status, status},
          {:headers, headers}
        ])

        :timer.sleep(retry)
        open(state)

      :data_error ->
        receive do
          {:gun_data, ^conn, ^ref, :fin,
           "no viable alternative at input" <> _ = t} ->
            parse_error(state, t)

          {:gun_data, ^conn, ^ref, :fin, "token recognition error at:" <> _ = t} ->
            parse_error(state, t)

          {:gun_data, ^conn, ^ref, :fin, "mismatched input" <> _ = t} ->
            parse_error(state, t)

          {:gun_data, ^conn, ^ref, :fin, "extraneous input" <> _ = t} ->
            parse_error(state, t)

          {:gun_data, ^conn, ^ref, :fin, "missing" <> _ = t} ->
            parse_error(state, t)

          {:gun_data, ^conn, ^ref, :fin, "parse error:" <> _ = t} ->
            parse_error(state, t)

          {:gun_data, ^conn, ^ref, :fin, t} ->
            :error_logger.info_report(get: t)
            Process.demonitor(m, [:flush])
            :gun.close(conn)

            :error_logger.info_report([
              {:fin, t}
            ])

            :timer.sleep(retry)
            open(state)

          {:gun_error, ^conn, ^ref, reason} ->
            {:error, reason}

          {:gun_error, ^conn, reason} ->
            {:error, reason}
        end
    end
  end

  defp parse_error(state, body) do
    :error_logger.info_report(parse_error: state, body: body)
    Kernel.send(self(), {:runlet_stdout, "query error: " <> body})
    Kernel.send(self(), :runlet_exit)
    Process.demonitor(state.m, [:flush])
    {:ok, state}
  end

  defp service(event, []) do
    event
  end

  defp service(event, [struct | structs]) do
    t =
      case struct do
        {as, n} ->
          Poison.Decode.decode(
            event,
            as: struct(as, Enum.map(n, fn {k, v} -> {k, struct(v)} end))
          )

        as ->
          Poison.Decode.decode(event, as: struct(as))
      end

    case Vex.valid?(t) do
      true -> t
      false -> service(event, structs)
    end
  end
end
