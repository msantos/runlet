defmodule Runlet.Cmd.Stdin do
  @moduledoc "Sends output from a pipeline to another process"

  @doc """
  Sends output from a pipeline to another process.
  """
  @spec exec(Enumerable.t(), Runlet.PID.t()) :: Enumerable.t()
  def exec(stream, name) when is_binary(name) do
    fifo = String.to_atom(name)

    Stream.each(stream, fn t ->
      try do
        Kernel.send(fifo, {:runlet_stdin, t})
      rescue
        ArgumentError ->
          :ok
      end
    end)
  end

  def exec(stream, pid) do
    Stream.each(stream, fn t ->
      Kernel.send(Runlet.PID.to_pid(pid), {:runlet_stdin, t})
    end)
  end
end
