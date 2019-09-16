defmodule Runlet.Event.Riemann do
  @moduledoc "Rieman JSON events"

  @derive [Poison.Encoder]

  defstruct [
    :host,
    :service,
    :state,
    :time,
    :description,
    :tags,
    :metric,
    :ttl
  ]

  @type t :: %__MODULE__{
          host: binary,
          service: binary,
          state: binary,
          time: binary,
          description: binary | :null,
          metric: integer | float | :null,
          tags: [binary] | nil,
          ttl: integer
        }

  use Vex.Struct

  validates(:host, presence: true)
  validates(:service, presence: true)
  validates(:time, presence: true)
  validates(:metric, presence: true)
end

require Runlet.Fmt

defimpl Runlet.Fmt, for: Runlet.Event.Riemann do
  def fmt(%Runlet.Event.Riemann{
        host: host,
        service: service,
        state: state,
        time: time,
        description: description,
        metric: metric
      }) do
    ~s(#{time} #{host} #{service} #{state} #{description} #{metric})
  end
end
