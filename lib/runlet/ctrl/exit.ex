defmodule Runlet.Ctrl.Exit do
  @moduledoc "Request a process to exit"

  @doc """
  Causes the event stream associated with a PID to exit.
  """
  @spec exec(Runlet.t(), integer | float) :: Enumerable.t()
  def exec(%Runlet{uid: uid} = env, pid), do: exec(env, pid, uid)

  def exec(_env, pid, uid) do
    result = Runlet.Process.pexit(uid, pid)

    [
      %Runlet.Event{
        event: %Runlet.Event.Ctrl{
          service: "exit",
          description: result,
          host: "#{node()}"
        },
        query: "exit #{uid} #{pid}"
      }
    ]
  end
end
