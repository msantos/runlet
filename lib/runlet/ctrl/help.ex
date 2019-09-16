defmodule Runlet.Ctrl.Help do
  @moduledoc "provide help for a command"

  @doc "provide command summaries"
  def exec(%Runlet{aliases: aliases}) do
    #  {"query",
    #  [{[:Runlet, :Cmd, :Query], :exec}, {{[:Runlet, :Cmd, :Valve], :exec}, []},
    #  {{[:Runlet, :Cmd, :Flow], :exec}, [20, 100]}]}
    #
    # {"valve", {[:Runlet, :Cmd, :Valve], :exec}}
    aliases
    |> Enum.map(fn
      {cmd, {mod, _}} ->
        "#{cmd}: #{moduledoc(Module.concat(mod))}"

      {cmd, [{{mod, _}, _} | _]} ->
        "#{cmd}: #{moduledoc(Module.concat(mod))}"

      {cmd, [{mod, _} | _]} ->
        "#{cmd}: #{moduledoc(Module.concat(mod))}"
    end)
    |> Enum.chunk_every(20, 20)
    |> Enum.map(fn t -> Enum.join(t, "\n\n") end)
    |> Enum.map(fn t ->
      %Runlet.Event{
        event: %Runlet.Event.Ctrl{
          service: "help",
          description: "Command Overview\n===============\n#{t}"
        },
        query: "help"
      }
    end)
  end

  defp moduledoc(mod) do
    case Code.fetch_docs(mod) do
      {:docs_v1, _, :elixir, _, %{"en" => descr}, _, _} ->
        descr

      _ ->
        "no description"
    end
  end

  @doc "provide help for command"
  def exec(%Runlet{aliases: aliases} = env, cmd) do
    ast =
      aliases
      |> List.keyfind(cmd, 0)

    case ast do
      nil ->
        [
          %Runlet.Event{
            event: %Runlet.Event.Ctrl{
              service: "help",
              description: "error: help not available: #{cmd}",
              host: "#{node()}"
            },
            query: "help #{cmd}"
          }
        ]

      mod ->
        doc(env, cmd, as_string(mod), Module.concat(to_mod(mod)))
    end
  end

  defp to_mod({_, {mod, _}}), do: mod
  defp to_mod({_, [{{mod, _}, _} | _]}), do: mod
  defp to_mod({_, [{mod, _} | _]}), do: mod

  defp as_string({_, mod}) when is_tuple(mod), do: [mod] |> ast_to_string()
  defp as_string({_, mod}) when is_list(mod), do: mod |> ast_to_string()

  defp ast_to_string(mod) do
    mod
    |> Enum.map(fn
      {{_, _}, _} = m ->
        Runlet.CLI.to_ast(m)

      {m, f} ->
        Runlet.CLI.to_ast({{m, f}, []})
    end)
    |> Runlet.CLI.pipe()
    |> Macro.to_string()
  end

  defp filter_arg(["runlet" | rest]), do: rest
  defp filter_arg(["env" | rest]), do: rest
  defp filter_arg(["stream" | rest]), do: rest
  defp filter_arg(x), do: x

  defp argv(<<"exec(", signature::binary>>) do
    signature
    |> String.trim_trailing(")")
    |> String.split(", ")
    |> filter_arg()
    |> Enum.flat_map(fn x -> ["<" <> x <> ">"] end)
    |> Enum.join(" ")
  end

  defp argv(_), do: []

  defp doc(_env, cmd, aliases, mod) do
    result =
      case Code.fetch_docs(mod) do
        {:docs_v1, _, :elixir, _, _, _, descr} ->
          {:ok, descr}

        _ ->
          {:error, "help not found"}
      end

    case result do
      {:error, err} ->
        [
          %Runlet.Event{
            event: %Runlet.Event.Ctrl{
              service: "help",
              description: """
              #{cmd}: #{err}
              """,
              host: "#{node()}"
            },
            query: "help #{cmd}"
          }
        ]

      {:ok, docs} ->
        docs
        |> Enum.flat_map(fn
          {{:function, :exec, _}, _, [arg], %{"en" => descr}, _}
          when is_binary(descr) ->
            [
              %Runlet.Event{
                event: %Runlet.Event.Ctrl{
                  service: "help",
                  description: """
                  usage: #{cmd}: #{argv(arg)}

                  #{descr}

                  Alias for: #{aliases}
                  """,
                  host: "#{node()}"
                },
                query: "help #{cmd}"
              }
            ]

          _ ->
            []
        end)
    end
  end
end
