defmodule Runlet.Cmd.Valve do
  @moduledoc "Asynchronously start/stop the event stream"

  defstruct tref: nil,
            open: true,
            dropped: 0

  @doc """
  Allows dynamically starting/stopping the event stream using the
  start/stop commands. While stopped, events are discarded.
  """
  @spec exec(Enumerable.t()) :: Enumerable.t()
  def exec(stream) do
    Stream.transform(
      stream,
      fn ->
        struct(Runlet.Cmd.Valve, [])
      end,
      fn
        %Runlet.Event{event: %Runlet.Event.Signal{}} = t, state ->
          {[t], state}

        t,
        %Runlet.Cmd.Valve{
          tref: tref,
          open: open,
          dropped: dropped
        } = state ->
          receive do
            {:runlet_close, seconds} when tref == nil and is_integer(seconds) ->
              {:ok, tref} = :timer.send_after(seconds * 1_000, :runlet_open)
              {[], %{state | tref: tref, open: false, dropped: dropped + 1}}

            {:runlet_close, seconds} when is_integer(seconds) ->
              _ = :timer.cancel(tref)
              {:ok, tref} = :timer.send_after(seconds * 1_000, :runlet_open)
              {[], %{state | tref: tref, open: false, dropped: dropped + 1}}

            {:runlet_close, _} when open == true ->
              {[
                 %{
                   t
                   | attr:
                       Map.merge(t.attr, %{
                         valve: %Runlet.Event.Valve{dropped: dropped}
                       })
                 }
               ], state}

            {:runlet_close, _} ->
              {[], %{state | dropped: dropped + 1}}

            :runlet_open when tref == nil ->
              {[
                 %{
                   t
                   | attr:
                       Map.merge(t.attr, %{
                         valve: %Runlet.Event.Valve{dropped: dropped}
                       })
                 }
               ], state}

            :runlet_open ->
              _ = :timer.cancel(tref)

              {[
                 %{
                   t
                   | attr:
                       Map.merge(t.attr, %{
                         valve: %Runlet.Event.Valve{dropped: dropped}
                       })
                 }
               ], %{state | tref: nil, open: true}}
          after
            0 ->
              case open do
                true ->
                  {[
                     %{
                       t
                       | attr:
                           Map.merge(t.attr, %{
                             valve: %Runlet.Event.Valve{dropped: dropped}
                           })
                     }
                   ], state}

                false ->
                  {[], %{state | dropped: dropped + 1}}
              end
          end
      end,
      fn
        %Runlet.Cmd.Valve{tref: nil} ->
          :ok

        %Runlet.Cmd.Valve{tref: tref} ->
          :timer.cancel(tref)
      end
    )
  end
end
