defmodule RunletCtrlSignalTest do
  use ExUnit.Case

  test "signal command" do
    pid = self() |> Runlet.PID.to_float()

    assert [%Runlet.Event{event: %Runlet.Event.Ctrl{}}] =
             Runlet.Ctrl.Signal.exec(%Runlet{}, pid)

    reply =
      receive do
        {:runlet_signal, "SIGHUP"} -> :ok
      after
        500 -> :timeout
      end

    assert :ok = reply

    assert [%Runlet.Event{event: %Runlet.Event.Ctrl{}}] =
             Runlet.Ctrl.Signal.exec(%Runlet{}, pid, "quit")

    reply =
      receive do
        {:runlet_signal, "SIGQUIT"} -> :ok
      after
        500 -> :timeout
      end

    assert :ok = reply
  end
end
