defmodule Runlet.Event.Stdin do
  @moduledoc "Runlet stdin"

  @derive [Poison.Encoder]

  defstruct service: "stdin",
            time: "",
            description: ""

  @type t :: %__MODULE__{
          service: binary,
          description: binary,
          time: binary
        }
end

require Runlet.Filter

defimpl Runlet.Filter, for: Runlet.Event.Stdin do
  def proto(
        %Runlet.Event.Stdin{
          description: nil
        },
        _
      ) do
    true
  end

  def proto(
        %Runlet.Event.Stdin{
          description: description
        },
        re
      ) do
    Regex.match?(re, description)
  end
end
