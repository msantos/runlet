defmodule Runlet.Cmd.Timeout do
  @moduledoc "Abort the event stream after a timeout"

  @doc """
  Terminates the stream if no events arrive before a timeout.
  """
  @spec exec(Enumerable.t(), pos_integer) :: Enumerable.t()
  def exec(stream, seconds) when seconds > 0 do
    timeout = seconds * 1_000

    Stream.transform(
      stream,
      fn ->
        ref = :erlang.make_ref()
        {:ok, tref} = :timer.send_after(timeout, {ref, 'runlet_timeout'})
        {:ok, kill} = :timer.exit_after(timeout, 'timeout')
        {tref, ref, kill}
      end,
      fn
        t, {tref, ref, nil} ->
          event(t, tref, ref, timeout)

        t, {tref, ref, kill} ->
          _ = :timer.cancel(kill)
          event(t, tref, ref, timeout)
      end,
      fn {tref, _, _} ->
        :timer.cancel(tref)
      end
    )
  end

  defp event(t, tref, ref, timeout) do
    receive do
      {^ref, 'runlet_timeout'} ->
        {:halt, {tref, ref, nil}}
    after
      0 ->
        _ = :timer.cancel(tref)
        ref1 = :erlang.make_ref()
        {:ok, tref1} = :timer.send_after(timeout, {ref1, 'runlet_timeout'})
        {[t], {tref1, ref1, nil}}
    end
  end
end
