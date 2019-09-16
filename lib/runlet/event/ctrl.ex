defmodule Runlet.Event.Ctrl do
  @moduledoc "Runlet control events"

  @derive [Poison.Encoder]

  defstruct host: "",
            service: "",
            description: "",
            time: ""

  @type t :: %__MODULE__{
          host: binary,
          service: binary,
          description: binary,
          time: binary
        }
end

require Runlet.Fmt

defimpl Runlet.Fmt, for: Runlet.Event.Ctrl do
  def fmt(%Runlet.Event.Ctrl{
        description: description
      }) do
    ~s(#{description})
  end
end
