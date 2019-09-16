defmodule RunletCtrlHistoryUserTest do
  use ExUnit.Case

  test "user history command" do
    Runlet.History.add("u1000", "runtime", 0)
    Runlet.History.add("u1001", "runtime", 0)
    Runlet.History.add("u1002", "runtime", 0)
    Runlet.History.add("u2000", "runtime", 0)

    assert [
             %Runlet.Event{
               event: %Runlet.Event.Ctrl{description: "u1000:\n0: runtime"}
             },
             %Runlet.Event{
               event: %Runlet.Event.Ctrl{description: "u1001:\n0: runtime"}
             },
             %Runlet.Event{
               event: %Runlet.Event.Ctrl{description: "u1002:\n0: runtime"}
             },
             %Runlet.Event{
               event: %Runlet.Event.Ctrl{description: "u2000:\n0: runtime"}
             }
           ] = Runlet.Ctrl.HistoryUser.exec(%Runlet{}, "u")

    assert [
             %Runlet.Event{
               event: %Runlet.Event.Ctrl{
                 description: "history: multiple matches: u1000, u1001, u1002"
               }
             }
           ] = Runlet.Ctrl.HistoryUser.exec(%Runlet{}, "u1", 0)

    assert [
             %Runlet.Event{
               event: %Runlet.Event.Ctrl{
                 description: "history: no match: noexist"
               }
             }
           ] = Runlet.Ctrl.HistoryUser.exec(%Runlet{}, "noexist", 0)

    assert [
             %Runlet.Event{
               event: %Runlet.Event.Ctrl{
                 description: "history: invalid index: 1"
               }
             }
           ] = Runlet.Ctrl.HistoryUser.exec(%Runlet{}, "u2", 1)

    assert [
             %Runlet.Event{
               event: %Runlet.Event.Ctrl{
                 description: <<"history: runtime: PID ", _::binary>>
               }
             }
           ] = Runlet.Ctrl.HistoryUser.exec(%Runlet{}, "u2", 0)
  end
end
