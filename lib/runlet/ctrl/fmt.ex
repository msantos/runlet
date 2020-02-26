defmodule Runlet.Ctrl.Fmt do
  @moduledoc "Toggle formatting of JSON"

  @doc """
  Enables/disables formatting of JSON for a process.
  """
  @spec exec(Runlet.t(), Runlet.PID.t()) :: Enumerable.t()
  def exec(%Runlet{uid: uid} = env, pid), do: exec(env, pid, uid)

  @spec exec(Runlet.t(), Runlet.PID.t(), String.t()) :: Enumerable.t()
  def exec(%Runlet{}, pid, uid) do
    result = Runlet.Process.format(uid, pid)

    [
      %Runlet.Event{
        event: %Runlet.Event.Ctrl{
          service: "kill",
          description: result,
          host: "#{node()}"
        },
        query: "fmt #{pid} #{uid}"
      }
    ]
  end
end
