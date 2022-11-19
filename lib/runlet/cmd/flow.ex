defmodule Runlet.Cmd.Flow do
  @moduledoc "Flow control events"

  defstruct count: 1000,
            seconds: 10,
            events: 0,
            dropped: 0,
            rate: 0,
            ts: 0

  @doc """
  Drop events that exceed a rate in count per seconds.
  """
  @spec exec(Enumerable.t(), pos_integer, pos_integer) :: Enumerable.t()
  def exec(stream, flow_count, flow_seconds)
      when flow_count > 0 and flow_seconds > 0 do
    Stream.transform(
      stream,
      fn ->
        %Runlet.Cmd.Flow{
          ts: System.monotonic_time(:second),
          count: flow_count,
          rate: flow_count,
          seconds: flow_seconds
        }
      end,
      fn
        %Runlet.Event{event: %Runlet.Event.Signal{}} = t, state ->
          {[t], state}

        t,
        %Runlet.Cmd.Flow{
          ts: ts,
          count: count,
          seconds: seconds,
          events: events,
          rate: rate,
          dropped: dropped
        } = state ->
          {ncount, nseconds} = get_rate_limit(count, seconds)

          now = System.monotonic_time(:second)

          rate = rate - (count - ncount)

          case {rate, now - ts < nseconds} do
            {n, true} when n < 1 ->
              # rate limit exceeded: drop events
              {[],
               %{
                 state
                 | count: ncount,
                   seconds: nseconds,
                   events: events + 1,
                   dropped: dropped + 1
               }}

            {_, false} ->
              # new rate window: reset counter
              {[
                 %{
                   t
                   | attr:
                       Map.merge(t.attr, %{
                         flow: %Runlet.Event.Flow{
                           events: events + 1,
                           dropped: dropped,
                           rate: ncount - 1
                         }
                       })
                 }
               ],
               %{
                 state
                 | ts: now,
                   count: ncount,
                   seconds: nseconds,
                   events: events + 1,
                   rate: ncount - 1
               }}

            {_, true} ->
              # below threshold: send event to stream
              {[
                 %{
                   t
                   | attr:
                       Map.merge(t.attr, %{
                         flow: %Runlet.Event.Flow{
                           events: events + 1,
                           dropped: dropped,
                           rate: rate - 1
                         }
                       })
                 }
               ],
               %{
                 state
                 | count: ncount,
                   seconds: nseconds,
                   events: events + 1,
                   rate: rate - 1
               }}
          end
      end,
      fn _ ->
        :ok
      end
    )
  end

  defp get_rate_limit(count0, seconds0) do
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
  end
end
