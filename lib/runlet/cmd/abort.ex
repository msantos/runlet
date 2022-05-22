defmodule Runlet.Cmd.Abort do
  @moduledoc "Abort pipeline if rate limit exceeded"

  @doc """
  Places a maximum rate limit on an event stream. Exceeding the limit
  terminates the process.

        # abort if number of events exceeds 5 in 2 minutes
        abort 5 120
  """
  @spec exec(Enumerable.t(), pos_integer, pos_integer) :: Enumerable.t()
  def exec(stream, limit, seconds \\ 60),
    do: exec(stream, limit, seconds, inspect(:erlang.make_ref()))

  @doc false
  @spec exec(Enumerable.t(), pos_integer, pos_integer, String.t()) ::
          Enumerable.t()
  def exec(stream, limit, seconds, name) when limit > 0 and seconds > 0 do
    milliseconds = seconds * 1_000

    Stream.transform(
      stream,
      fn -> nil end,
      fn
        %Runlet.Event{event: %Runlet.Event.Signal{}} = t, _ ->
          {[t], nil}

        t, _ ->
          case ExRated.check_rate(name, milliseconds, limit) do
            {:ok, _} -> {[t], nil}
            {:error, _} -> {:halt, nil}
          end
      end,
      fn _ ->
        ExRated.delete_bucket(name)
      end
    )
  end
end
