defmodule Runlet.Process do
  @moduledoc "Process job control"

  @type t :: {pid(), binary}

  @doc """
  Restarts running processes.
  """
  def start_link(stdout) do
    case Task.Supervisor.start_link(name: Runlet.Bootstrap) do
      {:ok, pid} ->
        _ =
          Task.Supervisor.start_child(Runlet.Bootstrap, fn ->
            boot(stdout)
          end)

        {:ok, pid}

      error ->
        error
    end
  end

  @doc """
  List available process tables.
  """
  @spec table() :: [binary]
  def table() do
    [Runlet.State.path(), "*", "process"]
    |> Path.join()
    |> Path.wildcard()
    |> Enum.map(fn t ->
      t |> Path.split() |> Enum.at(-2) |> Runlet.State.decode()
    end)
  end

  @doc """
  List process entries for a user.
  """
  @spec table(binary) :: [t]
  def table(name) do
    Runlet.State.table("process", name)
  end

  @doc """
  Restart saved processes.
  """
  @spec boot(fun) :: [any]
  def boot(stdout) do
    process_list =
      table()
      |> Enum.map(fn name -> {name, Runlet.State.table("process", name)} end)

    process_list
    |> Enum.map(fn {name, proc} ->
      Task.Supervisor.start_child(Runlet.Init, fn ->
        run_init(name, proc, stdout)
      end)
    end)
  end

  @spec run_init(binary, [t], fun) :: [any]
  defp run_init(name, proc, stdout) do
    proc
    |> Enum.map(fn {pid, cmd} ->
      _ = delete(name, pid)
      Runlet.fork(%Runlet{uid: name, pipeline: cmd, stdout: stdout})
    end)
  end

  @doc """
  Run saved processes for a user.
  """
  @spec run(binary, [t], fun) :: [any]
  def run(name, proc, stdout) do
    proc
    |> Enum.map(fn {pid, cmd} ->
      case alive?(pid) do
        true ->
          :ok

        false ->
          _ = delete(name, pid)
          Runlet.fork(%Runlet{uid: name, pipeline: cmd, stdout: stdout})
      end
    end)
  end

  @doc """
  Find a running command by PID.
  """
  @spec lookup(binary, Runlet.PID.t()) :: [t]
  def lookup(name, id) do
    pid = Runlet.PID.to_pid(id)

    "process"
    |> Runlet.State.table(name)
    |> Enum.filter(fn {p, _} -> p == pid end)
  end

  @doc """
  Add a command to a user's process table.
  """
  @spec add(binary, pid | Runlet.PID.t(), binary) :: :ok | {:error, any()}
  def add(user, pid, cmd)
      when is_binary(user) and is_binary(cmd) and is_pid(pid) do
    Runlet.State.add("process", user, pid, cmd)
  end

  @doc """
  Delete a command from a user's process table.
  """
  @spec delete(binary, pid | Runlet.PID.t()) :: :ok | {:error, any()}
  def delete(name, id) do
    pid = Runlet.PID.to_pid(id)
    Runlet.State.delete("process", name, pid)
  end

  @doc """
  Retrieve a formatted process table for a user.
  """
  @spec all(binary) :: [binary]
  def all(name) do
    "process"
    |> Runlet.State.table(name)
    |> Enum.map(fn {pid, cmd} ->
      "#{Runlet.PID.to_string(pid)}: #{cmd}"
    end)
    |> Enum.sort()
  end

  @doc """
  Return the list of running commands.
  """
  @spec running(binary) :: [binary]
  def running(name) do
    "process"
    |> Runlet.State.table(name)
    |> Enum.flat_map(fn {pid, cmd} ->
      case alive?(pid) do
        false -> []
        true -> [cmd]
      end
    end)
  end

  @doc """
  Tests if a PID is running.
  """
  @spec alive?(pid) :: boolean
  def alive?(pid), do: alive?(Runlet.Init, pid)

  defp alive?(supervisor, pid) do
    tasks = Task.Supervisor.children(supervisor)
    Enum.member?(tasks, pid)
  end

  @doc """
  Terminate a process for a user.
  """
  @spec kill(binary, Runlet.PID.t()) :: binary
  def kill(name, id) do
    match(name, id, fn pid, cmd ->
      _ = Task.Supervisor.terminate_child(Runlet.Init, pid)
      "process killed: #{cmd}"
    end)
  end

  @doc """
  Suppresses output for a process for the given number of minutes.
  """
  @spec stop(binary, Runlet.PID.t(), non_neg_integer) :: binary
  def stop(name, id, minutes \\ 60) do
    match(name, id, fn pid, cmd ->
      Kernel.send(pid, {:runlet_close, minutes * 60})
      "process stopped for #{minutes} minute(s): #{cmd}"
    end)
  end

  @doc """
  Starts a stopped process.
  """
  @spec start(binary, Runlet.PID.t()) :: binary
  def start(name, id) do
    match(name, id, fn pid, cmd ->
      Kernel.send(pid, :runlet_open)
      "process started: #{cmd}"
    end)
  end

  @doc """
  Force a process to exit.
  """
  @spec pexit(binary, Runlet.PID.t()) :: binary
  def pexit(name, id) do
    match(name, id, fn pid, cmd ->
      Kernel.send(pid, :runlet_exit)
      "process exited: #{cmd}"
    end)
  end

  @doc """
  Sets the number of events allowed in a period of time (minutes). Events
  exceeding this limit are dropped.
  """
  @spec limit(binary, Runlet.PID.t(), pos_integer, pos_integer) :: binary
  def limit(name, id, count \\ 1, minutes \\ 1) do
    match(name, id, fn pid, cmd ->
      Kernel.send(pid, {:runlet_limit, count, minutes * 60})
      "process limited to #{count} events/#{minutes} minute(s): #{cmd}"
    end)
  end

  @doc """
  Toggle formatting of events.
  """
  @spec format(binary, Runlet.PID.t()) :: binary
  def format(name, id) do
    match(name, id, fn pid, cmd ->
      Kernel.send(pid, :runlet_fmt)
      "toggling formatting: #{cmd}"
    end)
  end

  @spec match(binary, Runlet.PID.t(), (pid, binary -> binary)) :: binary
  def match(name, id, fun) do
    case lookup(name, id) do
      [] ->
        "process: invalid id: #{id}"

      [{pid, cmd}] ->
        case Process.alive?(pid) do
          false ->
            _ = delete(name, pid)
            "process not running: #{cmd} : #{id}"

          true ->
            fun.(pid, cmd)
        end
    end
  end
end
