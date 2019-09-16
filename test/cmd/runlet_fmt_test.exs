defmodule RunletCmdFmtTest do
  use ExUnit.Case

  test "fmt" do
    e = %Runlet.Event.Stdout{
      service: "service",
      host: "host",
      description: <<"test", 0, 3>>
    }

    result =
      10
      |> Stream.interval()
      |> Stream.map(fn _ -> %Runlet.Event{event: e} end)
      |> Runlet.Cmd.Fmt.exec()
      |> Enum.take(1)

    assert ["```\nhost service test%00%03" <> _] = result
  end
end
