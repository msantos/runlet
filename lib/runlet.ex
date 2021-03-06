defmodule Runlet do
  @moduledoc false

  defstruct uid: "nobody",
            pipeline: "",
            stdout: nil,
            aliases: nil,
            append: "fmt",
            state: nil

  @type t :: %__MODULE__{
          uid: binary,
          pipeline: binary,
          stdout: (String.t() -> (Runlet.Event.t() | String.t() -> any)) | nil,
          aliases: Runlet.CLI.t() | nil,
          state: any
        }

  def start_link() do
    Task.Supervisor.start_link(name: Runlet.Init)
  end

  @spec fork(t) :: {:ok, pid} | {:error, String.t()}
  def fork(%Runlet{} = initial_env) do
    %Runlet{
      uid: uid,
      pipeline: pipeline
    } = env = default(initial_env)

    with {:ok, %{code: code, jobctrl: jobctrl}} <- compile(env) do
      Task.Supervisor.start_child(Runlet.Init, fn ->
        child = self()

        Kernel.spawn(fn ->
          Process.monitor(child)

          receive do
            {:DOWN, _, :process, _, _} ->
              :ok

            error ->
              :error_logger.error_report(error)
          end

          Runlet.Process.delete(uid, child)
        end)

        _ = if not jobctrl, do: Runlet.History.add(uid, pipeline, child)
        _ = Runlet.Process.add(uid, child, pipeline)
        exec(env, code)
      end)
    end
  end

  @spec exec(Runlet.t(), [Runlet.CLI.t()]) :: :ok
  def exec(%Runlet{stdout: fun} = env, pipeline) do
    stdout = fun.(env)

    pipeline
    |> Runlet.CLI.exec(env: env)
    |> Stream.each(fn io -> stdout.(io) end)
    |> Stream.run()
  end

  @spec compile(Runlet.t()) ::
          {:ok, %{code: [Runlet.CLI.t()], jobctrl: boolean}}
          | {:error, String.t()}
  def compile(%Runlet{pipeline: pipeline, aliases: aliases} = env) do
    with {:ok, code} <- Runlet.CLI.parse(pipeline),
         {:ok, ast0} <- append(env, code),
         {:ok, ast} <- Runlet.CLI.ast(ast0, aliases) do
      p =
        case jobctrl?(ast) do
          true ->
            %{
              code:
                Runlet.CLI.pipe(List.insert_at(ast, 0, Macro.var(:env, nil))),
              jobctrl: true
            }

          false ->
            %{code: Runlet.CLI.pipe(ast), jobctrl: false}
        end

      {:ok, p}
    end
  end

  @spec append(%Runlet{append: binary | Runlet.CLI.t()}, [Runlet.CLI.t()]) ::
          {:ok, [Runlet.CLI.t()]} | {:error, String.t()}
  defp append(%Runlet{append: nil}, pipeline) do
    {:ok, pipeline}
  end

  defp append(%Runlet{}, [{<<"\\", _::binary>>, _} | _] = pipeline) do
    {:ok, pipeline}
  end

  defp append(%Runlet{append: insn}, pipeline) do
    pos =
      case List.last(pipeline) do
        {redirect, _} when redirect == ">" or redirect == "stdin" ->
          -2

        _ ->
          -1
      end

    Runlet.CLI.insert(pipeline, insn, pos)
  end

  defp default_stdout() do
    pid = self()

    fn _uid ->
      fn t -> Kernel.send(pid, {:runlet_stdout, t}) end
    end
  end

  defp default(%Runlet{} = env) do
    stdout =
      case env.stdout do
        nil -> default_stdout()
        fun -> fun
      end

    aliases =
      case env.aliases do
        nil -> Runlet.CLI.aliases()
        commands -> commands
      end

    %{env | stdout: stdout, aliases: aliases}
  end

  def jobctrl?([{{_, _, [{_, _, [_, :Ctrl, _]}, _]}, _, _} | _]), do: true
  def jobctrl?(_), do: false
end
