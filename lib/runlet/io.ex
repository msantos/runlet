defmodule Runlet.IO do
  @moduledoc false

  @doc """
  Display stream of events in the shell.

    Runlet.CLI.compile!("test | foo") |> Runlet.CLI.exec!() |> Runlet.IO.debug() |> Stream.run()
  """
  @spec debug(Enumerable.t()) :: Enumerable.t()
  def debug(stream) do
    Stream.each(stream, fn t -> :error_logger.info_report(t) end)
  end

  @doc """
  Send stream of events to another process.
  """
  @spec send(Enumerable.t(), pid) :: Enumerable.t()
  def send(stream, pid) do
    Stream.each(stream, fn t -> Kernel.send(pid, {:runlet, t}) end)
  end
end
