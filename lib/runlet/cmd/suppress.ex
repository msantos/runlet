defmodule Runlet.Cmd.Suppress do
  @moduledoc "Ignore events for a time period in seconds"

  defstruct tref: nil,
            ref: nil,
            active: false

  @type t :: %__MODULE__{
          tref: :timer.tref() | nil,
          ref: reference | nil,
          active: boolean
        }

  @doc """
  Sets a timer and ignores any events until the timer fires.

  Can be used for long running commands that always output on start.

  Args:

    suppress <seconds>
  """
  @spec exec(Enumerable.t(), pos_integer) :: Enumerable.t()
  def exec(stream, seconds) when seconds > 0 do
    timeout = seconds * 1_000

    Stream.transform(
      stream,
      fn ->
        ref = :erlang.make_ref()
        {:ok, tref} = :timer.send_after(timeout, {ref, 'runlet_suppress'})
        %Runlet.Cmd.Suppress{tref: tref, ref: ref}
      end,
      fn
        %Runlet.Event{event: %Runlet.Event.Signal{}} = t, state ->
          {[t], state}

        t, state ->
          event(t, state)
      end,
      fn %Runlet.Cmd.Suppress{tref: tref} ->
        :timer.cancel(tref)
      end
    )
  end

  defp event(t, %Runlet.Cmd.Suppress{active: true} = state), do: {[t], state}

  defp event(t, %Runlet.Cmd.Suppress{ref: ref, active: false} = state) do
    receive do
      {^ref, 'runlet_suppress'} ->
        {[t], %{state | active: true}}
    after
      0 ->
        {[], state}
    end
  end
end
