defmodule Runlet.Event.Stdout do
  @moduledoc "Runlet stdout events"

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

defimpl Runlet.Fmt, for: Runlet.Event.Stdout do
  def fmt(%Runlet.Event.Stdout{
        host: host,
        service: service,
        description: description
      }) do
    ~s(```\n#{host} #{service} #{description}\n```)
  end
end

require Runlet.Filter

defimpl Runlet.Filter, for: Runlet.Event.Stdout do
  def proto(
        %Runlet.Event.Stdout{
          description: nil
        },
        _
      ) do
    true
  end

  def proto(
        %Runlet.Event.Stdout{
          description: description
        },
        re
      ) do
    Regex.match?(re, description)
  end
end
