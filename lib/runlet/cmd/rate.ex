defmodule Runlet.Cmd.Rate do
  @moduledoc "Calculate event rate"

  @doc """
  Generates an event every *seconds* seconds consisting of the event
  stream rate per second.
  """
  @spec exec(Enumerable.t(), pos_integer) :: Enumerable.t()
  def exec(stream, seconds \\ 60) when seconds > 0 do
    Stream.transform(
      stream,
      fn ->
        {:ok, tref} =
          :timer.send_interval(seconds * 1_000, {:runlet_signal, "SIGALRM"})

        %{count: 0, tref: tref}
      end,
      fn
        %Runlet.Event{event: %Runlet.Event.Signal{}}, %{count: count} = state ->
          {[
             %Runlet.Event{
               :event => %Runlet.Event.Stdout{
                 description: "#{Float.round(count / seconds, 2)}/sec"
               },
               :query => "rate"
             }
           ], %{state | count: 0}}

        %Runlet.Event{event: event}, state ->
          {[], Runlet.Rate.rate(event, state)}
      end,
      fn %{tref: tref} ->
        _ = :timer.cancel(tref)
        :ok
      end
    )
  end
end
