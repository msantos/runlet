defmodule RunletCtrlKillTest do
  use ExUnit.Case

  test "kill command: PID" do
    assert [%Runlet.Event{event: %Runlet.Event.Ctrl{}}] =
             Runlet.Ctrl.Kill.exec(%Runlet{uid: "test"}, 1234)
  end

  test "kill command: PID, user" do
    assert [%Runlet.Event{event: %Runlet.Event.Ctrl{}}] =
             Runlet.Ctrl.Kill.exec(%Runlet{}, 1234, "test")
  end

  test "kill command: list of PIDs" do
    assert [
             %Runlet.Event{event: %Runlet.Event.Ctrl{}},
             %Runlet.Event{event: %Runlet.Event.Ctrl{}},
             %Runlet.Event{event: %Runlet.Event.Ctrl{}}
           ] = Runlet.Ctrl.Kill.exec(%Runlet{uid: "test"}, "1234 1235 1236")
  end

  test "kill command: list of PIDs and user" do
    assert [
             %Runlet.Event{event: %Runlet.Event.Ctrl{}},
             %Runlet.Event{event: %Runlet.Event.Ctrl{}},
             %Runlet.Event{event: %Runlet.Event.Ctrl{}}
           ] = Runlet.Ctrl.Kill.exec(%Runlet{}, "1234 1235 1236", "test")
  end

  test "kill command: invalid PID" do
    assert_raise MatchError, fn ->
      Runlet.Ctrl.Kill.exec(%Runlet{uid: "test"}, "foo")
    end
  end

  test "kill command: list with invalid PID" do
    assert_raise MatchError, fn ->
      Runlet.Ctrl.Kill.exec(%Runlet{uid: "test"}, "1234 1235 foo 1236")
    end
  end
end
