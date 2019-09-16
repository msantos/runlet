defmodule RunletSelectTest do
  use ExUnit.Case

  test "select" do
    e = %Runlet.Event.Stdout{
      service: "service",
      host: "host",
      description: "test"
    }

    result =
      [%Runlet.Event{event: e}]
      |> Stream.cycle()
      |> Runlet.Cmd.Select.exec("description")
      |> Enum.take(2)

    assert [
             %Runlet.Event{attr: %{}, event: %{description: "test"}, query: ""},
             %Runlet.Event{attr: %{}, event: %{description: "test"}, query: ""}
           ] = result
  end
end
