defmodule Runlet.Ctrl.Kill do
  @moduledoc "Terminate a running event stream process"

  @doc """
  Terminate the process running an event stream.
  """
  @spec exec(Runlet.t(), integer | float, binary) :: Enumerable.t()
  def exec(%Runlet{uid: uid} = env, pid), do: exec(env, pid, uid)

  @doc """
  Terminate a process run by another user.
  """
  def exec(_env, pid, uid) do
    result = Runlet.Process.kill(uid, pid)

    [
      %Runlet.Event{
        event: %Runlet.Event.Ctrl{
          service: "kill",
          description: result,
          host: "#{node()}"
        },
        query: "kill #{pid} #{uid}"
      }
    ]
  end
end
