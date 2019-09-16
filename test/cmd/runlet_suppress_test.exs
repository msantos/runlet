defmodule RunletSuppressTest do
  use ExUnit.Case

  test "suppress" do
    e = %Runlet.Event.Stdout{
      service: "service",
      host: "host",
      description: "test"
    }

    t1 = :erlang.monotonic_time(:seconds)

    result =
      10
      |> Stream.interval()
      |> Stream.map(fn _ -> %Runlet.Event{event: e} end)
      |> Runlet.Cmd.Suppress.exec(2)
      |> Enum.take(1)

    t2 = :erlang.monotonic_time(:seconds)

    assert 1 = length(result)
    assert 2 <= t2 - t1
  end
end
