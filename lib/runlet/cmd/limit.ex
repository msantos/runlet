defmodule Runlet.Cmd.Limit do
  @moduledoc "Limit events to count per seconds"

  defstruct count: 0,
            ts: 0

  @doc """
  Set upper limit on the number of events permitted per *seconds*
  seconds. Events exceeding this rate are discarded.
  """
  @spec exec(Enumerable.t(), pos_integer, pos_integer) :: Enumerable.t()
  def exec(stream, limit, seconds \\ 60) when limit > 0 and seconds > 0 do
    milliseconds = seconds * 1_000

    Stream.transform(
      stream,
      fn ->
        %Runlet.Cmd.Limit{ts: System.monotonic_time(:millisecond)}
      end,
      fn
        %Runlet.Event{event: %Runlet.Event.Signal{}} = t, state ->
          {[t], state}

        t, %Runlet.Cmd.Limit{count: count} = state when count < limit ->
          {[t], %{state | count: count + 1}}

        t, %Runlet.Cmd.Limit{ts: ts} = state ->
          now = System.monotonic_time(:millisecond)

          case now - ts < milliseconds do
            true ->
              {[
                 %Runlet.Event{
                   event: %Runlet.Event.Ctrl{
                     service: "limit",
                     description:
                       "limit reached: new events will be dropped (#{limit} events/#{seconds} seconds)",
                     host: "#{node()}"
                   },
                   query: "limit #{limit} #{seconds}"
                 }
               ], state}

            false ->
              {[t], %{state | ts: now, count: 0}}
          end
      end,
      fn _ ->
        :ok
      end
    )
  end
end
