defmodule RunletCmdFifoTest do
  use ExUnit.Case
  doctest Runlet

  test "Send input via a nonexistent fifo" do
    {:ok, _} =
      Runlet.fork(%Runlet{
        uid: "runlet_test",
        pipeline: ~s(runtime > foo)
      })

    reply =
      receive do
        {:runlet_stdout, t} ->
          t

        error ->
          error
      after
        0 ->
          :ok
      end

    assert :ok = reply
  end

  test "Send input via a fifo" do
    {:ok, _} =
      Runlet.fork(%Runlet{
        uid: "runlet_test",
        pipeline: ~s(fifo pipe)
      })

    {:ok, _} =
      Runlet.fork(%Runlet{
        uid: "runlet_test",
        pipeline: ~s(runtime > pipe)
      })

    reply =
      receive do
        {:runlet_stdout, _} ->
          :ok

        error ->
          error
      after
        1000 ->
          :timeout
      end

    assert :ok = reply
  end
end
