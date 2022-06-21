defmodule RunletLimitTest do
  use ExUnit.Case

  test "limit" do
    e = %Runlet.Event.Stdout{
      service: "service",
      host: "host",
      description: "test"
    }

    x =
      100
      |> Stream.interval()
      |> Stream.map(fn _ -> %Runlet.Event{event: e} end)
      |> Runlet.Cmd.Limit.exec(1, 60)
      |> Enum.take(2)

    assert [
             %Runlet.Event{
               attr: %{},
               event: %Runlet.Event.Stdout{
                 description: "test",
                 host: "host",
                 service: "service",
                 time: ""
               },
               query: ""
             },
             %Runlet.Event{
               attr: %{},
               event: %Runlet.Event.Ctrl{
                 description:
                   "limit reached: new events will be dropped (1 events/60 seconds)",
                 host: "nonode@nohost",
                 service: "limit",
                 time: ""
               },
               query: "limit 1 60"
             }
           ] = x
  end
end
