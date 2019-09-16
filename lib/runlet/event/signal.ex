defmodule Runlet.Event.Signal do
  @moduledoc "Runlet signal events"

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

defimpl Runlet.Fmt, for: Runlet.Event.Signal do
  def fmt(%Runlet.Event.Signal{
        host: host,
        service: service,
        description: description
      }) do
    ~s(#{host} #{service} #{description})
  end
end
