defmodule RunletCLITest do
  use ExUnit.Case
  doctest Runlet.CLI

  test "parser: string used as command" do
    assert {:ok, [{:string, 1, ~c"a string"}], 1} =
             Runlet.CLI.lex("\"a string\"")

    assert {:error, "syntax error before: \"a string\""} =
             Runlet.CLI.parse("\"a string\"")
  end

  test "parse: integer used as command" do
    assert {:ok, [{:integer, 1, 1}], 1} = Runlet.CLI.lex("1")
    assert {:error, "syntax error before: 1"} = Runlet.CLI.parse("1")
  end

  test "parse: commands" do
    # command command
    assert {:ok, [{"help", ["foo"]}]} = Runlet.CLI.parse(~S(help foo))
    assert {:ok, [{"help", ["foo"]}]} = Runlet.CLI.parse(~S(help "foo"))

    # command pid string
    assert {:ok, [{"signal", [1, "TERM"]}]} =
             Runlet.CLI.parse(~S(signal 1 "TERM"))

    assert {:ok, [{"signal", [1.0, "TERM"]}]} =
             Runlet.CLI.parse(~S(signal 1.0 "TERM"))

    # command pid integer integer
    assert {:ok, [{"reflow", [1, 10, 20]}]} =
             Runlet.CLI.parse(~S(reflow 1 10 20))

    assert {:ok, [{"reflow", [1.1, 10, 20]}]} =
             Runlet.CLI.parse(~S(reflow 1.1 10 20))

    assert {:ok, [{"reflow", ["1 1.1 2.2", 10, 20]}]} =
             Runlet.CLI.parse(~S(reflow "1 1.1 2.2" 10 20))
  end
end
