defmodule Runlet.Cmd.Query do
  require Logger

  @moduledoc "Query a riemann server"

  defstruct url: "",
            host: "",
            port: 80,
            query: "",
            retry: 3_000,
            conn: nil,
            ref: nil,
            m: nil

  @type t :: %__MODULE__{
          url: String.t(),
          host: String.t(),
          port: non_neg_integer,
          query: String.t(),
          retry: non_neg_integer,
          conn: pid | nil,
          ref: reference | nil,
          m: reference | nil
        }

  @riemann_url "/event/index?query="
  @riemann_host "localhost"
  @riemann_port "8080"

  defp riemann_url,
    do: Runlet.Config.get(:runlet, :riemann_url, @riemann_url)

  defp riemann_host,
    do: Runlet.Config.get(:runlet, :riemann_host, @riemann_host)

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
      query: q
    }

    startfun = fn ->
      open(cfg)
    end

    resourcefun = fn %Runlet.Cmd.Query{conn: conn, ref: ref, m: m} = state ->
      receive do
        {:gun_sse, ^conn, ^ref, %{event_type: "message", data: data}} ->
          case service(data, structs) do
            {:ok, e} ->
              {[%Runlet.Event{query: q, event: e}], state}

            {:error, error} ->
              Logger.error(%{json_parse: error, query: q, data: data})
              {[], state}
          end

        {:gun_sse, ^conn, ^ref, event} ->
          Logger.info(%{gun_sse: event})
          {[], state}

        {:gun_sse, conn, _, _} ->
          :gun.close(conn)
          {[], state}

        {:gun_error, ^conn, ^ref, reason} ->
          Logger.error(%{gun_error: reason})
          Process.demonitor(m, [:flush])
          close(state)
          t = open(state)
          {[], t}

        {:gun_error, conn, _, _} ->
          :gun.close(conn)
          {[], state}

        {:gun_error, ^conn, reason} ->
          Logger.error(%{gun_error: reason})
          Process.demonitor(m, [:flush])
          close(state)
          t = open(state)
          {[], t}

        {:gun_error, conn, _} ->
          :gun.close(conn)
          {[], state}

        {:gun_down, conn, _, reason, streams, _} ->
          Logger.info(%{gun_down: reason, streams: streams})
          :gun.close(conn)
          {[], state}

        {:gun_up, _, _} ->
          Logger.info(%{gun_up: "reconnecting"})
          t = get(state)
          {[], t}

        {:DOWN, ^m, :process, _, _} ->
          Logger.info(%{down: "reconnecting"})
          close(state)
          t = open(state)
          {[], t}

        {:DOWN, _, :process, _, _} ->
          {[], state}

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
          close(%{state | retry: 0})
          t = open(state)

          {[
             %Runlet.Event{
               query: q,
               event: %Runlet.Event.Signal{description: "SIGHUP"}
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

          # unhandled ->
          #   Logger.info(%{unhandled_resource: unhandled})
          #   {[], state}
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

  @spec open(t) :: t
  defp open(%Runlet.Cmd.Query{host: host, port: port, retry: retry} = state) do
    opt = %{
      protocols: [:http],
      http_opts: %{content_handlers: [:gun_sse_h, :gun_data_h]},
      connect_timeout: retry,
      retry: 3,
      retry_timeout: retry
    }

    result = :gun.open(String.to_charlist(host), port, opt)

    case result do
      {:ok, conn} ->
        m = Process.monitor(conn)

        case :gun.await_up(conn, m) do
          {:ok, _} ->
            get(%{state | conn: conn, m: m})

          {:error, error} ->
            Process.demonitor(m, [:flush])
            Logger.error(%{gun_await_up: error})
            close(state)
            open(state)
        end

      {:error, error} ->
        Logger.info(%{gun_open: error})
        :timer.sleep(retry)
        open(state)
    end
  end

  @spec close(t) :: :ok
  defp close(%Runlet.Cmd.Query{conn: conn, retry: retry}) do
    :gun.close(conn)
    :timer.sleep(retry)
  end

  @spec get(t) :: t
  defp get(
         %Runlet.Cmd.Query{
           url: url,
           query: query0,
           m: m,
           conn: conn
         } = state0
       ) do
    query =
      query0
      |> URI.encode(&URI.char_unreserved?/1)

    ref =
      :gun.get(conn, String.to_charlist(url <> query), [
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
      {:ok, n} ->
        n

      {:error, _} = error ->
        Process.demonitor(m, [:flush])
        Logger.info(%{gun_get: error})
        close(state)
        open(state)

      {:open, is_fin, status, headers} ->
        Process.demonitor(m, [:flush])

        Logger.info(%{
          fin: is_fin,
          status: status,
          headers: headers
        })

        close(state)
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
            Logger.info(%{fin: t})
            Process.demonitor(m, [:flush])
            close(state)
            open(state)

          {:gun_error, ^conn, ^ref, reason} ->
            Logger.info(%{gun_error: reason})
            Process.demonitor(m, [:flush])
            close(state)
            open(state)

          {:gun_error, ^conn, reason} ->
            Logger.info(%{gun_error: reason})
            Process.demonitor(m, [:flush])
            close(state)
            open(state)
        end
    end
  end

  defp parse_error(state, body) do
    Logger.info(%{parse_error: state, body: body})
    Kernel.send(self(), {:runlet_stdout, "query error: " <> body})
    Kernel.send(self(), :runlet_exit)
    Process.demonitor(state.m, [:flush])
    state
  end

  defp service(event, []) do
    Poison.decode(event)
  end

  defp service(event, [struct | structs]) do
    e =
      case struct do
        {as, n} ->
          Poison.decode(
            event,
            as: struct(as, Enum.map(n, fn {k, v} -> {k, struct(v)} end))
          )

        as ->
          Poison.decode(event, as: struct(as))
      end

    case e do
      {:ok, t} ->
        case Vex.valid?(t) do
          true -> e
          false -> service(event, structs)
        end

      {:error, _} ->
        service(event, structs)
    end
  end
end
