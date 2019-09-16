defmodule RunletGrepTest do
  use ExUnit.Case

  test "grep" do
    e = [
      %Runlet.Event{
        event: %Runlet.Event.Stdout{
          service: "service",
          host: "host",
          description: "test"
        }
      },
      %Runlet.Event{
        event: %Runlet.Event.Stdout{
          service: "service",
          host: "host",
          description: "abc"
        }
      },
      %Runlet.Event{
        event: %Runlet.Event.Stdout{
          service: "service",
          host: "host",
          description: "def"
        }
      },
      %Runlet.Event{
        event: %Runlet.Event.Stdout{
          service: "service",
          host: "host",
          description: "ghi"
        }
      },
      %Runlet.Event{
        event: %Runlet.Event.Stdout{
          service: "service",
          host: "host",
          description: "xyz"
        }
      }
    ]

    result =
      e
      |> Stream.cycle()
      |> Runlet.Cmd.Grep.exec("def")
      |> Enum.take(3)
      |> Enum.reject(fn t -> t.event.description == "def" end)

    assert [] = result
  end
end
