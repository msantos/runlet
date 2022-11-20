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

        t, %Runlet.Cmd.Threshold{count: count, buf: buf} = state
        when count < limit ->
          ms = System.monotonic_time(:second)
          event = {ms, t}
          {[], %{state | buf: filter(ms, seconds, [event | buf])}}

        t, %Runlet.Cmd.Threshold{ts: ts, buf: buf} = state ->
          ms = System.monotonic_time(:second)
          event = {ms, t}

          case ms - ts < seconds do
            true ->
              {to_list([event | buf]), %{state | ts: ms, count: 1, buf: []}}

            false ->
              {[], %{state | buf: [event]}}
          end
      end,
      fn _ ->
        :ok
      end
    )
  end

  defp filter(ms, expiry, buf) do
    Enum.filter(buf, fn
      {ms0, _} when ms - ms0 < expiry -> true
      _ -> false
    end)
  end

  defp to_list(buf) do
    buf
    |> Enum.map(fn {_, t} -> t end)
    |> Enum.reverse()
  end
end
