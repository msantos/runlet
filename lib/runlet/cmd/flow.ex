defmodule Runlet.Cmd.Flow do
  @moduledoc "Flow control events"

  defstruct count: 1000,
            seconds: 10,
            events: 0,
            dropped: 0,
            ts: 0

  @doc """
  Drop events that exceed a rate in count per seconds.
  """
  @spec exec(Enumerable.t(), pos_integer, pos_integer) :: Enumerable.t()
  def exec(stream, flow_count, flow_seconds)
      when flow_count > 0 and flow_seconds > 0 do
    name = inspect(:erlang.make_ref())

    Stream.transform(
      stream,
      fn ->
        struct(
          Runlet.Cmd.Flow,
          count: flow_count,
          seconds: flow_seconds,
          ts: now()
        )
      end,
      fn
        %Runlet.Event{event: %Runlet.Event.Signal{}} = t, state ->
          {[t], state}

        t,
        %Runlet.Cmd.Flow{
          count: count0,
          seconds: seconds0,
          events: events0,
          dropped: dropped,
          ts: ts
        } = state ->
          {limit, scale} =
            receive do
              {:runlet_limit, count, seconds}
              when is_integer(count) and is_integer(seconds) and count > 0 and
                     seconds > 0 ->
                {count, seconds}

              {:runlet_limit, _, _} ->
                {count0, seconds0}
            after
              0 ->
                {count0, seconds0}
            end

          events = events0 + 1

          case ExRated.check_rate(name, scale * 1_000, limit) do
            {:ok, _} ->
              elapsed = elapsed(ts)

              {[
                 %{
                   t
                   | attr:
                       Map.merge(t.attr, %{
                         flow: %Runlet.Event.Flow{
                           events: events,
                           dropped: dropped,
                           rate: events / elapsed
                         }
                       })
                 }
               ],
               struct(
                 state,
                 count: limit,
                 seconds: scale,
                 events: events,
                 dropped: dropped
               )}

            {:error, _} ->
              {[],
               struct(
                 state,
                 count: limit,
                 seconds: scale,
                 events: events,
                 dropped: dropped + 1
               )}
          end
      end,
      fn _ ->
        ExRated.delete_bucket(name)
        :ok
      end
    )
  end

  @spec now() :: pos_integer
  defp now(), do: :erlang.system_time(:seconds)

  @spec elapsed(pos_integer) :: pos_integer
  defp elapsed(ts) do
    case now() - ts do
      x when x > 0 -> x
      _ -> 1
    end
  end
end
