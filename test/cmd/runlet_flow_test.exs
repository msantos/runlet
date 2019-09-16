defmodule RunletFlowTest do
  use ExUnit.Case

  test "flow" do
    e = %Runlet.Event.Stdout{
      service: "service",
      host: "host",
      description: "test"
    }

    result =
      [%Runlet.Event{event: e}]
      |> Stream.cycle()
      |> Runlet.Cmd.Flow.exec(1, 1)
      # |> Runlet.IO.debug()
      |> Enum.take(5)

    z = List.last(result)

    dropped = z.attr.flow.dropped
    events = z.attr.flow.events
    rate = z.attr.flow.rate
    count = z.attr.flow.events - z.attr.flow.dropped

    assert dropped > 5
    assert events > 5
    assert rate > 1
    assert ^count = 5
  end
end
