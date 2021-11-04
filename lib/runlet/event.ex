defmodule Runlet.Event do
  @moduledoc "Runlet events"

  defstruct event: %{},
            query: "",
            attr: %{}

  @type t :: %__MODULE__{
          event: any,
          query: binary,
          attr: %{optional(atom) => integer | float | binary}
        }

  @doc """
  Convert the contained event to a map.
  """
  @spec to_map(struct() | map()) :: map()
  def to_map(e) when is_struct(e), do: Map.from_struct(e)
  def to_map(e) when is_map(e), do: e

  @doc """
  Takes all entries corresponding to the given keys in the contained
  event and extracts them into a separate map.
  """
  @spec split(struct() | map(), [any()]) :: {map(), map()}
  def split(e, k), do: e |> to_map() |> Map.split(k)
end

require Runlet.Fmt

defimpl Runlet.Fmt, for: Runlet.Event do
  @spec fmt(Runlet.Event.t()) :: binary
  def fmt(event) do
    Poison.encode!(event, pretty: true)
  end
end
