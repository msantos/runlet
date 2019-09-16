defmodule RunletRuntimeTest do
  use ExUnit.Case

  test "exec" do
    [z] = Runlet.Cmd.Runtime.exec() |> Enum.take(10)

    assert_raise RuntimeError,
                 ~r/^[0-9]+ days, [0-9] hours, [0-9]+ minutes and [0-9]+ seconds$/,
                 fn ->
                   raise z.event.description
                 end
  end
end
