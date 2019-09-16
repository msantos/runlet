defmodule Runlet.Cmd.Flow do
  @moduledoc "Flow control events"

  defstruct count: 1000,
            seconds: 10,
            events: 0,
            dropped: 0,
            max: 1000,
            ts: 0

  @doc """
  Drop events that exceed a rate in count per seconds.
  """
  @spec exec(Enumerable.t(), pos_integer, pos_integer) :: Enumerable.t()
  def exec(stream, flow_count, flow_seconds) do
    exec(stream, flow_count, flow_seconds, 1000)
  end

  @doc """
  Drop events that exceed a rate in count per seconds.

  The flow_max argument specifies a high water mark for the number
  of queued messages. If the maximum is exceeded, all queued messages
  are dropped.
  """
  @spec exec(Enumerable.t(), pos_integer, pos_integer, pos_integer) ::
          Enumerable.t()
  def exec(stream, flow_count, flow_seconds, flow_max)
      when flow_count > 0 and flow_seconds > 0 and flow_max > 0 do
    name = inspect(:erlang.make_ref())

    Stream.transform(
      stream,
      fn ->
        struct(
          Runlet.Cmd.Flow,
          count: flow_count,
          seconds: flow_seconds,
          max: flow_max,
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
          max: max,
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

          flushed = pending_events(max)

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
                 dropped: dropped + flushed
               )}

            {:error, _} ->
              {[],
               struct(
                 state,
                 count: limit,
                 seconds: scale,
                 events: events,
                 dropped: dropped + 1 + flushed
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

  defp pending_events(n) do
    case Process.info(self(), :message_queue_len) do
      {:message_queue_len, x} when x < n ->
        0

      {:message_queue_len, _} ->
        flush_queue()
    end
  end

  defp flush_queue(), do: flush_queue(0)

  defp flush_queue(x) do
    receive do
      _ -> flush_queue(x + 1)
    after
      0 -> x
    end
  end
end
