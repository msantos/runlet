defmodule Runlet.Cmd.Select do
  @moduledoc "Select keys from JSON"

  @doc """
  Select a subset of keys from the JSON key/value pairs.
  """
  @spec exec(Enumerable.t(), String.t()) :: Enumerable.t()
  def exec(stream, keys) do
    k =
      keys
      |> String.split(" ")
      |> Enum.map(fn t -> String.to_existing_atom(t) end)

    Stream.map(stream, fn
      %Runlet.Event{event: %Runlet.Event.Signal{}} = t ->
        t

      %Runlet.Event{event: e} = t ->
        {selected, _} = e |> Runlet.Event.split(k)
        %{t | event: selected}
    end)
  end
end
