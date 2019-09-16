defmodule RunletRateTest do
  use ExUnit.Case

  test "rate" do
    [z] =
      source()
      |> Runlet.Cmd.Rate.exec(1)
      |> Enum.take(1)

    assert_raise RuntimeError, ~r/^[1-9][0-9]+\.[0-9]\/sec$/, fn ->
      raise z.event.description
    end
  end

  defp source() do
    e = %Runlet.Event{event: %Runlet.Event.Stdout{description: "service"}}
    {:ok, alrm} = :timer.send_interval(1_000, {:runlet_signal, "SIGALRM"})
    {:ok, tref} = :timer.send_interval(10, :runlet_rate_test)

    Stream.resource(
      fn -> nil end,
      fn _ ->
        receive do
          :runlet_rate_test ->
            {[e], nil}

          {:runlet_signal, signal} ->
            {[
               %Runlet.Event{
                 query: "runlet_rate_test",
                 event: %Runlet.Event.Signal{description: signal}
               }
             ], nil}
        end
      end,
      fn _ ->
        :timer.cancel(alrm)
        :timer.cancel(tref)
      end
    )
  end
end
