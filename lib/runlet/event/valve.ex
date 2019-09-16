defmodule Runlet.Event.Valve do
  @moduledoc "Runlet valve events"

  @derive [Poison.Encoder]

  defstruct dropped: 0

  @type t :: %__MODULE__{
          dropped: non_neg_integer
        }
end

require Runlet.Fmt

defimpl Runlet.Fmt, for: Runlet.Event.Valve do
  def fmt(%Runlet.Event.Valve{
        dropped: dropped
      })
      when dropped > 0 do
    "(valve: #{dropped} dropped)"
  end

  def fmt(_) do
    ""
  end
end
