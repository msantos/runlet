defmodule RunletAbortTest do
  use ExUnit.Case

  test "abort" do
    e = %Runlet.Event.Stdout{
      service: "service",
      host: "host",
      description: "test"
    }

    result =
      [%Runlet.Event{event: e}]
      |> Stream.cycle()
      |> Runlet.Cmd.Abort.exec(10)
      |> Enum.take(20)

    assert 10 = length(result)
  end
end
