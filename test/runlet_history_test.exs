defmodule RunletHistoryTest do
  use ExUnit.Case
  doctest Runlet.History

  test "Retrieve all history for user" do
    run("runlet_history_test")
  end

  test "Retrieve all history for percent encoded user" do
    run("runlet_history_@#$%^")
  end

  defp run(name) do
    assert [] = Runlet.History.all(name)

    assert :ok = Runlet.History.add(name, "runtime", self())
    assert ["0: runtime"] = Runlet.History.all(name)
    assert {"runtime", _} = Runlet.History.lookup(name, 0)

    assert :ok = Runlet.History.add(name, "test | foo", self())
    assert ["0: test | foo", "1: runtime"] = Runlet.History.all(name)
    assert :ok = Runlet.History.delete(name, [0, 1])
    assert [] = Runlet.History.all(name)
  end
end
