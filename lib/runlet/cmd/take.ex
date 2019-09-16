defmodule Runlet.Cmd.Take do
  @moduledoc "Take a number of events from the stream"

  @doc """
  Takes *count* events from the stream and terminates the stream.
  """
  @spec exec(Enumerable.t(), integer) :: Enumerable.t()
  def exec(stream, count) do
    Stream.transform(stream, 0, fn
      %Runlet.Event{event: %Runlet.Event.Signal{}} = t, n ->
        {[t], n}

      t, n when n < count ->
        {[t], n + 1}

      _, n ->
        {:halt, n}
    end)
  end
end
