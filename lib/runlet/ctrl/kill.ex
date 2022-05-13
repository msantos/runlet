defmodule Runlet.Ctrl.Kill do
  @moduledoc "Terminate a running event stream process"

  @doc """
  Terminate the process running an event stream. Accepts a PID or a list
  of PIDs:

      kill 1234
      kill "1234"
      kill "1234 123.5 1256"
  """
  @spec exec(Runlet.t(), Runlet.PID.t() | String.t(), String.t()) ::
          Enumerable.t()
  def exec(%Runlet{uid: uid}, pid), do: kill(pid, uid)

  @doc """
  Terminate a process run by another user. Accepts a PID of a list
  of PIDs:

      kill 1234 "name"
      kill "1234" "name"
      kill "1234 123.5 1256" "name"
  """
  def exec(_env, pid, uid), do: kill(pid, uid)

  defp kill(pid, uid) when is_binary(pid) do
    pid
    |> String.split()
    |> Enum.map(fn t -> Runlet.PID.to_float(t) end)
    |> Enum.map(fn t -> signal(t, uid) end)
  end

  defp kill(pid, uid) when is_integer(pid) or is_float(pid) do
    [signal(pid, uid)]
  end

  defp signal(pid, uid) do
    result = Runlet.Process.kill(uid, pid)

    %Runlet.Event{
      event: %Runlet.Event.Ctrl{
        service: "kill",
        description: result,
        host: "#{node()}"
      },
      query: "kill #{pid} #{uid}"
    }
  end
end
