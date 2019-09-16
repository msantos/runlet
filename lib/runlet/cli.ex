defmodule Runlet.CLI do
  @moduledoc "Compile runlet expresions"

  @type t :: {[atom], atom} | {{[atom], atom}, [String.t() | integer]}
  @type e :: String.t() | [t]

  @spec aliases() :: [t]
  def aliases(), do: Runlet.Config.get(:runlet, :aliases, [])

  def exec(ast), do: exec!(ast, [])
  def exec(ast, bind), do: exec!(ast, bind)

  def exec!(ast), do: exec!(ast, [])

  def exec!(ast, bind) do
    {code, _} = Code.eval_quoted(ast, bind, __ENV__)
    code
  end

  @doc ~S"""
  Compile a runlet expression into the AST

  Commands are looked up in the application environment:

    Application.get_env(:runlet, :aliases, [])
  """
  @spec compile!(e) :: [t]
  def compile!(pipeline) do
    compile!(pipeline, aliases())
  end

  @doc ~S"""
  Compile a runlet expression into Elixr AST

  ## Examples

    iex> Runlet.CLI.compile!(
    ...>   ~s(test "foo" | bar 123),
    ...>   [{"test", [{[:Fake, :Cmd, :AddArg], :exec},
    ...>              {{:Fake, :Cmd, :StaticArg}, ["static arg"]}]},
    ...>    {"bar", {[:Fake, :Cmd, :IntArg], :exec}}])
    {:|>, [context: Elixir, import: Kernel],
     [{:|>, [context: Elixir, import: Kernel],
       [{{:., [], [{:__aliases__, [alias: false], [:Fake, :Cmd, :AddArg]}, :exec]},
         [], ["foo"]},
        {{:., [],
          [{:__aliases__, [alias: false], {:Fake, :Cmd, :StaticArg}},
           ["static arg"]]}, [], ["foo"]}]},
      {{:., [], [{:__aliases__, [alias: false], [:Fake, :Cmd, :IntArg]}, :exec]},
       [], '{'}]}
  """
  @spec compile!(e, [t]) :: [t]
  def compile!(pipeline, commands) do
    case compile(pipeline, commands) do
      {:error, error} -> throw(error)
      {:ok, insn} -> insn
    end
  end

  @doc ~S"""
  Compile a runlet expression into Elixr AST

  Commands are looked up in the application environment:

    Application.get_env(:runlet, :aliases, [])
  """
  @spec compile(e) :: {:ok, [t]} | {:error, String.t()}
  def compile(pipeline) do
    compile(pipeline, aliases())
  end

  @doc ~S"""
  Compile a runlet expression into the AST

  ## Examples

    iex> Runlet.CLI.compile(
    ...>   ~s(test "foo" | bar 123),
    ...>   [{"test", [{[:Fake, :Cmd, :AddArg], :exec},
    ...>              {{:Fake, :Cmd, :StaticArg}, ["static arg"]}]},
    ...>    {"bar", {[:Fake, :Cmd, :IntArg], :exec}}])
    {:ok,
     {:|>, [context: Elixir, import: Kernel],
      [{:|>, [context: Elixir, import: Kernel],
        [{{:., [], [{:__aliases__, [alias: false], [:Fake, :Cmd, :AddArg]}, :exec]},
          [], ["foo"]},
         {{:., [],
           [{:__aliases__, [alias: false], {:Fake, :Cmd, :StaticArg}},
            ["static arg"]]}, [], ["foo"]}]},
       {{:., [], [{:__aliases__, [alias: false], [:Fake, :Cmd, :IntArg]}, :exec]},
        [], '{'}]}}
  """
  @spec compile(e, [t]) :: {:ok, [t]} | {:error, String.t()}
  def compile(pipeline, commands) do
    with {:ok, code} <- ast(pipeline, commands) do
      {:ok, pipe(code)}
    end
  end

  def ast(pipeline, commands) do
    fun = fn {cmd, arg} ->
      case List.keyfind(commands, cmd, 0) do
        nil ->
          {:error, "#{cmd}: not found"}

        {^cmd, {{_mod, _fun}, _argv} = t} ->
          {:ok, [t]}

        {^cmd, {mod, fun}} ->
          {:ok, [{{mod, fun}, arg}]}

        {^cmd, form} when is_list(form) ->
          insn =
            form
            |> Enum.map(fn
              {{_mod, _fun}, _argv} = t -> t
              {mod, fun} -> {{mod, fun}, arg}
            end)
            |> Enum.reverse()

          {:ok, insn}
      end
    end

    with {:ok, command} <- parse(pipeline),
         {:ok, code} <- expand(command, fun) do
      {:ok, code}
    end
  end

  def pipe(code) do
    Enum.reduce(code, fn term, acc ->
      {:|>, [context: Elixir, import: Kernel], [acc, term]}
    end)
  end

  @spec expand([t], fun) :: {:ok, [t]} | {:error, String.t()}
  def expand(pipeline, fun) do
    with {:ok, cmds} <- substitute(pipeline, fun) do
      {:ok, Enum.map(cmds, fn cmd -> to_ast(cmd) end)}
    end
  end

  @spec substitute([t], fun) :: {:ok, [t]} | {:error, String.t()}
  def substitute(cmds, fun), do: substitute(cmds, fun, [])

  def substitute([], _fun, acc) do
    {:ok, Enum.reverse(List.flatten(acc))}
  end

  def substitute([cmd | cmds], fun, acc) do
    case fun.(cmd) do
      {:error, _} = error ->
        error

      {:ok, form} ->
        substitute(cmds, fun, [form | acc])
    end
  end

  def to_ast({{mod, fun}, arg}) do
    {{:., [], [{:__aliases__, [alias: false], mod}, fun]}, [], arg}
  end

  def lex(command) do
    command
    |> String.to_charlist()
    |> :runlet_lexer.string()
  end

  @doc ~S"""
  Parse a runlet expression.

  ## Examples

    iex(7)> Runlet.CLI.parse(~s(test "foo" | bar 123 | out > 456))
    {:ok, [{"test", ["foo"]}, {"bar", '{'}, {"out", []}, {">", [456]}]}
  """
  @spec parse(e) ::
          {:ok, [{String.t(), [integer | float | String.t()]}]}
          | {:error, String.t()}
  def parse(command) when is_binary(command) do
    result =
      with {:ok, tokens, _} <- lex(command),
           {:ok, pipeline} <- :runlet_parser.parse(tokens) do
        {:ok, pipeline}
      end

    case result do
      {:error, {_line, :runlet_lexer, error}, _n} ->
        {:error, "#{:runlet_lexer.format_error(error)}"}

      {:error, {_line, :runlet_parser, error}} ->
        {:error, "#{:runlet_parser.format_error(error)}"}

      {:ok, pipeline} ->
        {:ok, pipeline}
    end
  end

  def parse(command) when is_list(command), do: {:ok, command}

  @doc ~S"""
  Insert a runlet pipeline into another pipeline.

  ## Examples

    iex> Runlet.CLI.insert(~s(test "foo" | bar 123 | another),
    ...>   ~s(insert | here), 2)
    {:ok,
     [{"test", ["foo"]}, {"bar", '{'}, {"insert", []}, {"here", []},
      {"another", []}]}
  """
  @spec insert(e, String.t() | [t], integer) ::
          {:ok, [t]} | {:error, String.t()}
  def insert(pipeline, command, position) do
    with {:ok, code} <- parse(pipeline),
         {:ok, insn} <- parse(command) do
      {:ok,
       code
       |> List.insert_at(position, insn)
       |> List.flatten()}
    end
  end

  @doc ~S"""
  Add a runlet expression at the start of a pipeline.

  ## Examples

    iex> Runlet.CLI.prepend(~s(test "foo" | bar 123 | another), ~s(insert | here))
    {:ok,
     [{"insert", []}, {"here", []}, {"test", ["foo"]}, {"bar", '{'},
      {"another", []}]}
  """
  @spec prepend(e, e) :: {:ok, [t]} | {:error, String.t()}
  def prepend(code, command), do: insert(code, command, 0)

  @doc ~S"""
  Add a runlet expression to the end of a pipeline.

  ## Examples

    iex> Runlet.CLI.append(~s(test "foo" | bar 123 | another), ~s(insert | here))
    {:ok,
     [{"test", ["foo"]}, {"bar", '{'}, {"another", []}, {"insert", []},
      {"here", []}]}
  """
  @spec append(e, e) :: {:ok, [t]} | {:error, String.t()}
  def append(code, command), do: insert(code, command, -1)
end
