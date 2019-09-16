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
end

require Runlet.Fmt

defimpl Runlet.Fmt, for: Runlet.Event do
  @spec fmt(Runlet.Event.t()) :: binary
  def fmt(event) do
    Poison.encode!(event, pretty: true)
  end
end
