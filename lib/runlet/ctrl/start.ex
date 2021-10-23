defmodule Runlet.Ctrl.Start do
  @moduledoc "Start a stopped process"

  @doc """
  Start a process.
  """
  def exec(%Runlet{uid: uid} = env, pid), do: exec(env, pid, uid)

  @doc """
  Start multiple processes.
  """
  @spec exec(Runlet.t(), String.t(), String.t()) :: Enumerable.t()
  def exec(env, pid, uid) when is_binary(pid) do
    pid
    |> String.split()
    |> Enum.map(fn t -> Runlet.PID.to_float(t) end)
    |> Enum.map(fn t -> exec(env, t, uid) end)
  end

  @spec exec(Runlet.t(), Runlet.PID.t(), String.t()) :: Enumerable.t()
  def exec(_env, pid, uid) when is_integer(pid) do
    result = Runlet.Process.start(uid, pid)

    [
      %Runlet.Event{
        event: %Runlet.Event.Ctrl{
          service: "start",
          description: result,
          host: "#{node()}"
        },
        query: "start #{pid} #{uid}"
      }
    ]
  end
end
