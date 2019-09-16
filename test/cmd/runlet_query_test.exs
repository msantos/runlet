defmodule RunletQueryTest do
  use ExUnit.Case

  test "exec" do
    # http://127.0.0.1:8080/event/index?query=
    server = System.fetch_env!("RUNLET_QUERY_TEST_SERVER")
    uri = URI.parse(server)

    Application.put_env(:runlet, :riemann_host, uri.host)
    Application.put_env(:runlet, :riemann_port, "#{uri.port}")

    Application.put_env(
      :runlet,
      :riemann_url,
      URI.to_string(%URI{path: uri.path, query: uri.query})
    )

    simple_query = "true" |> Runlet.Cmd.Query.exec() |> Enum.take(1)

    no_viable_alternative =
      "service = " |> Runlet.Cmd.Query.exec() |> Enum.take(2)

    token_recognition_error =
      "service = \"" |> Runlet.Cmd.Query.exec() |> Enum.take(2)

    extraneous_input =
      "service = \"true\" foo" |> Runlet.Cmd.Query.exec() |> Enum.take(2)

    missing = "(service = \"true\"" |> Runlet.Cmd.Query.exec() |> Enum.take(2)

    assert [%Runlet.Event{}] = simple_query

    assert [
             %Runlet.Event{
               event: %Runlet.Event.Stdout{
                 description:
                   "query error: no viable alternative at input '<EOF>'"
               }
             }
           ] = no_viable_alternative

    assert [
             %Runlet.Event{
               event: %Runlet.Event.Stdout{
                 description: "query error: token recognition error at:" <> _
               }
             }
           ] = token_recognition_error

    assert [
             %Runlet.Event{
               event: %Runlet.Event.Stdout{
                 description: "query error: extraneous input" <> _
               }
             }
           ] = extraneous_input

    assert [
             %Runlet.Event{
               event: %Runlet.Event.Stdout{
                 description: "query error: missing" <> _
               }
             }
           ] = missing
  end
end
