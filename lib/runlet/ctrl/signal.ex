defmodule Runlet.Ctrl.Signal do
  @moduledoc "Send a signal to a process"

  @doc """
  Sends SIGHUP to a process.
  """
  @spec exec(Runlet.t(), binary | integer | float) :: Enumerable.t()
  def exec(env, pid), do: exec(env, pid, "hup")

  @doc """
  Sends a signal to a process.
  """
  @spec exec(Runlet.t(), binary | integer | float, binary) :: Enumerable.t()
  def exec(env, pid, signal) when is_binary(pid) do
    pid
    |> String.split()
    |> Enum.map(fn t -> Runlet.PID.to_float(t) end)
    |> Enum.map(fn t -> exec(env, t, signal) end)
  end

  def exec(%Runlet{}, pid, signal) when is_integer(pid) or is_float(pid) do
    Kernel.send(Runlet.PID.to_pid(pid), {:runlet_signal, to_signal(signal)})

    [
      %Runlet.Event{
        event: %Runlet.Event.Ctrl{
          service: "signal",
          description: "sent #{pid} #{signal}",
          host: "#{node()}"
        },
        query: "signal #{pid} #{signal}"
      }
    ]
  end

  defp to_signal(<<"alrm">>), do: "SIGALRM"
  defp to_signal(<<"cont">>), do: "SIGCONT"
  defp to_signal(<<"hup">>), do: "SIGHUP"
  defp to_signal(<<"int">>), do: "SIGTERM"
  defp to_signal(<<"kill">>), do: "SIGKILL"
  defp to_signal(<<"quit">>), do: "SIGQUIT"
  defp to_signal(<<"stop">>), do: "SIGSTOP"
  defp to_signal(<<"stp">>), do: "SIGSTOP"
  defp to_signal(<<"term">>), do: "SIGTERM"
  defp to_signal(sig) when is_binary(sig), do: sig
end
