defmodule RunletTest do
  use ExUnit.Case
  doctest Runlet

  test "Fork a process" do
    {:ok, _} =
      Runlet.fork(%Runlet{
        uid: "runlet_test",
        pipeline: ~s(runtime)
      })

    reply =
      receive do
        {:runlet_stdout, _} -> :ok
        error -> error
      after
        1000 -> :timeout
      end

    assert :ok = reply
  end
end
