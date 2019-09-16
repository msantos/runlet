defmodule RunletFmtTest do
  use ExUnit.Case

  test "atom" do
    assert "" = Runlet.Fmt.fmt(nil)
    assert "" = Runlet.Fmt.fmt(:null)
    assert "test" = Runlet.Fmt.fmt(:test)
  end

  test "map" do
    assert "%{test: \"abc\"}" = Runlet.Fmt.fmt(%{test: "abc"})
  end
end
