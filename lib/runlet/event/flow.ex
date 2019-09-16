defmodule Runlet.Event.Flow do
  @moduledoc "Runlet flow events"

  @derive [Poison.Encoder]

  defstruct events: 0,
            dropped: 0,
            rate: 0

  @type t :: %__MODULE__{
          events: non_neg_integer,
          dropped: non_neg_integer,
          rate: float
        }
end

require Runlet.Fmt

defimpl Runlet.Fmt, for: Runlet.Event.Flow do
  def fmt(%Runlet.Event.Flow{
        events: events,
        dropped: dropped,
        rate: rate
      }) do
    "(flow: #{events} events, #{dropped} dropped, #{Float.round(rate, 2)}/sec)"
  end
end
