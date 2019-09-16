defmodule RunletProcessTest do
  use ExUnit.Case
  doctest Runlet.Process

  test "Job control" do
    run("runlet_process_test")
  end

  test "Job control: percent encoded name" do
    run("runlet_process_@#$%^")
  end

  defp run(name) do
    assert [] = Runlet.Process.all(name)

    cmd = "test"

    {:ok, child} =
      Runlet.fork(%Runlet{
        uid: name,
        pipeline: cmd,
        aliases: [
          {"test", {{[:RunletProcessTest, :Cycle], :exec}, []}},
          {"fmt", {[:Runlet, :Cmd, :Fmt], :exec}}
        ]
      })

    receive do
      {:runlet_stdout, _} -> :ok
    end

    # XXX wait for the monitor process to exit and clean up state
    :timer.sleep(1000)

    assert [_] = Runlet.Process.all(name)
    assert [{^child, ^cmd}] = Runlet.Process.lookup(name, child)

    assert <<"process killed: ", ^cmd::binary>> =
             Runlet.Process.kill(name, child)

    :timer.sleep(100)
    assert [] = Runlet.Process.all(name)
  end
end

defmodule RunletProcessTest.Cycle do
  def exec() do
    Stream.cycle([
      %Runlet.Event{
        event: %Runlet.Event.Stdout{
          description: "test"
        }
      }
    ])
  end
end
