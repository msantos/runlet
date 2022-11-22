defmodule Runlet.Cmd.Threshold do
  @moduledoc "Passes events over a minimum limit"

  defstruct count: 0,
            ts: 0,
            buf: []

  @doc """
  Events below the threshold are suppressed. If the number of events in
  *seconds* seconds exceeds the threshold, all events, including events
  that were suppressed, are passed.
  """
  @spec exec(Enumerable.t(), pos_integer, pos_integer) :: Enumerable.t()
  def exec(stream, limit, seconds \\ 60) when limit > 0 and seconds > 0 do
    Stream.transform(
      stream,
      fn ->
        %Runlet.Cmd.Threshold{ts: System.monotonic_time(:second)}
      end,
      fn
        %Runlet.Event{event: %Runlet.Event.Signal{}} = t, state ->
          {[t], state}

        t, %Runlet.Cmd.Threshold{ts: ts0, count: count, buf: buf} = state ->
          ts = System.monotonic_time(:second)
          event = {ts, t}

          case {ts - ts0 < seconds, count < limit} do
            {true, true} ->
              {[],
               %{
                 state
                 | buf: filter(ts, seconds, [event | buf]),
                   count: count + 1
               }}

            {true, false} ->
              {to_list([event | buf]), %{state | ts: ts, count: 1, buf: []}}

            {false, _} ->
              {[], %{state | buf: [event], count: 1}}
          end
      end,
      fn _ ->
        :ok
      end
    )
  end

  defp filter(ts, expiry, buf) do
    Enum.filter(buf, fn
      {ts0, _} when ts - ts0 < expiry -> true
      _ -> false
    end)
  end

  defp to_list(buf) do
    buf
    |> Enum.map(fn {_, t} -> t end)
    |> Enum.reverse()
  end
end
