defmodule Runlet.Cmd.Abort do
  @moduledoc "Abort pipeline if rate limit exceeded"

  defstruct count: 0,
            ts: 0

  @doc """
  Places a maximum rate limit on an event stream. Exceeding the limit
  terminates the process.

        # abort if number of events exceeds 5 in 2 minutes
        abort 5 120
  """
  @spec exec(Enumerable.t(), pos_integer, pos_integer) :: Enumerable.t()
  def exec(stream, limit, seconds \\ 60) when limit > 0 and seconds > 0 do
    Stream.transform(
      stream,
      fn ->
        %Runlet.Cmd.Abort{ts: System.monotonic_time(:second), count: 0}
      end,
      fn
        %Runlet.Event{event: %Runlet.Event.Signal{}} = t, state ->
          {[t], state}

        t, %Runlet.Cmd.Abort{count: count} = state when count < limit ->
          {[t], %{state | count: count + 1}}

        t, %Runlet.Cmd.Abort{ts: ts} = state ->
          now = System.monotonic_time(:second)

          case now - ts < seconds do
            true ->
              {:halt, state}

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
