defmodule Runlet.Cmd.Threshold do
  @moduledoc "Passes events over a minimum limit"

  @doc """
  Events below the threshold are suppressed. If the number of events in
  *seconds* seconds exceeds the threshold, all events, including events
  that were suppressed, are passed.
  """
  @spec exec(Enumerable.t(), pos_integer, pos_integer) :: Enumerable.t()
  def exec(stream, count, seconds \\ 60),
    do: exec(stream, count, seconds, inspect(:erlang.make_ref()))

  @doc false
  @spec exec(Enumerable.t(), pos_integer, pos_integer, String.t()) ::
          Enumerable.t()
  def exec(stream, count, seconds, name) when count > 0 and seconds > 0 do
    milliseconds = seconds * 1_000

    Stream.transform(
      stream,
      fn -> [] end,
      fn
        %Runlet.Event{event: %Runlet.Event.Signal{}} = t, buf ->
          {[t], buf}

        t, buf ->
          ts = now()
          event = {ts, t}

          case ExRated.check_rate(name, milliseconds, count) do
            {:ok, _} ->
              {[], filter(ts, seconds, [event | buf])}

            {:error, _} ->
              {to_list([event | buf]), []}
          end
      end,
      fn _ ->
        ExRated.delete_bucket(name)
      end
    )
  end

  @spec now() :: pos_integer
  defp now(), do: :erlang.system_time(:seconds)

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
