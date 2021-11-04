defmodule RunletDedupTest do
  use ExUnit.Case

  test "dedup" do
    e = %Runlet.Event.Stdout{
      service: "service",
      host: "host",
      description: "test"
    }

    e1 = %{e | description: "abc"}

    result =
      [e, e, e, e, e1, e1, e, e1]
      |> Enum.map(fn t -> %Runlet.Event{event: t} end)
      |> Runlet.Cmd.Dedup.exec("host service", "description")
      |> Enum.take(8)

    expect = [
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
        event: %Runlet.Event.Stdout{
          description: "abc",
          host: "host",
          service: "service",
          time: ""
        },
        query: ""
      },
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
        event: %Runlet.Event.Stdout{
          description: "abc",
          host: "host",
          service: "service",
          time: ""
        },
        query: ""
      }
    ]

    assert ^expect = result
  end

  test "event is a map" do
    e = %Runlet.Event.Stdout{
      service: "service",
      host: "host",
      description: "test"
    }

    e1 = %{
      "host" => "host",
      "service" => "service",
      "state" => "expired"
    }

    result =
      [e, e, e1, e1]
      |> Enum.map(fn t -> %Runlet.Event{event: t} end)
      |> Runlet.Cmd.Dedup.exec("host service", "description")
      |> Enum.take(8)

    expect = [
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
        event: %{
          "host" => "host",
          "service" => "service",
          "state" => "expired"
        }
      }
    ]

    assert ^expect = result
  end
end
