defmodule RunletTakeTest do
  use ExUnit.Case

  test "take" do
    e = %Runlet.Event.Stdout{
      service: "service",
      host: "host",
      description: "test"
    }

    result =
      10
      |> Stream.interval()
      |> Stream.map(fn _ -> %Runlet.Event{event: e} end)
      |> Runlet.Cmd.Take.exec(2)
      |> Enum.take(3)

    assert 2 <= length(result)

    e = %Runlet.Event.Signal{description: "SIGALARM"}

    result =
      10
      |> Stream.interval()
      |> Stream.map(fn _ -> %Runlet.Event{event: e} end)
      |> Runlet.Cmd.Take.exec(2)
      |> Enum.take(4)

    assert 4 <= length(result)
  end
end
