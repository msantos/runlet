defmodule Runlet.Ctrl.Stop do
  @moduledoc "Silence output from running process"

  @doc """
  Stops output from a running process. The process continues to run.
  After *timeout* minutes passes, output from the process resumes.
  """
  @spec exec(Runlet.t(), String.t() | integer | float, pos_integer) ::
          Enumerable.t()
  def exec(%Runlet{uid: uid} = env, pid, timeout \\ 60),
    do: exec(env, pid, timeout, uid)

  @doc """
  Stops output stream for list of processes.
  """
  @spec exec(Runlet.t(), String.t() | integer | float, pos_integer, String.t()) ::
          Enumerable.t()
  def exec(env, pid, timeout, uid) when is_binary(pid) do
    pid
    |> String.split()
    |> Enum.map(fn t -> Runlet.PID.to_float(t) end)
    |> Enum.map(fn t -> exec(env, t, timeout, uid) end)
  end

  @doc """
  Stops output stream for a user's process.
  """
  def exec(_env, pid, timeout, uid) when is_integer(pid) or is_float(pid) do
    result = Runlet.Process.stop(uid, pid, timeout)

    [
      %Runlet.Event{
        event: %Runlet.Event.Ctrl{
          service: "stop",
          description: result,
          host: "#{node()}"
        },
        query: "stop #{pid} #{timeout} #{uid}"
      }
    ]
  end
end
