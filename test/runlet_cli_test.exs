defmodule RunletCLITest do
  use ExUnit.Case
  doctest Runlet.CLI

  test "parser: string used as command" do
    assert {:ok, [{:string, 1, 'a string'}], 1} = Runlet.CLI.lex("\"a string\"")

    assert {:error, "syntax error before: \"a string\""} =
             Runlet.CLI.parse("\"a string\"")
  end

  test "parse: integer used as command" do
    assert {:ok, [{:integer, 1, 1}], 1} = Runlet.CLI.lex("1")
    assert {:error, "syntax error before: 1"} = Runlet.CLI.parse("1")
  end
end
