defmodule RunletSignalPipelineTest do
  use ExUnit.Case

  test "signals are not flow controlled" do
    e = %Runlet.Event.Stdout{
      service: "service",
      host: "host",
      description: "test"
    }

    s = %Runlet.Event.Signal{description: "SIGALRM"}

    Kernel.send(self(), {:runlet_close, 720})

    t1 = :erlang.monotonic_time(:seconds)

    result =
      10
      |> Stream.interval()
      |> Stream.transform(0, fn
        _t, n when n < 20 ->
          {[%Runlet.Event{event: e}], n + 1}

        _t, n ->
          {[%Runlet.Event{event: s}], n + 1}
      end)
      |> Runlet.Cmd.Threshold.exec(100, 120)
      |> Runlet.Cmd.Limit.exec(1, 360)
      |> Runlet.Cmd.Take.exec(10)
      |> Runlet.Cmd.Valve.exec()
      |> Enum.take(1)

    t2 = :erlang.monotonic_time(:seconds)

    assert 1 = length(result)
    assert 2 > t2 - t1
  end
end
