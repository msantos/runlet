defmodule Runlet.Cmd.Limit do
  @moduledoc "Limit events to count per seconds"

  @doc """
  Set upper limit on the number of events permitted per *seconds*
  seconds. Events exceeding this rate are discarded.
  """
  @spec exec(Enumerable.t(), pos_integer, pos_integer) :: Enumerable.t()
  def exec(stream, count, seconds \\ 60) do
    exec(stream, count, seconds, inspect(:erlang.make_ref()))
  end

  @doc false
  @spec exec(Enumerable.t(), pos_integer, pos_integer, String.t()) ::
          Enumerable.t()
  def exec(stream, limit, seconds, name) when limit > 0 and seconds > 0 do
    milliseconds = seconds * 1_000

    Stream.transform(
      stream,
      fn -> true end,
      fn
        %Runlet.Event{event: %Runlet.Event.Signal{}} = t, alert ->
          {[t], alert}

        t, alert ->
          case {ExRated.check_rate(name, milliseconds, limit), alert} do
            {{:ok, _}, _} ->
              {[t], true}

            {{:error, _}, true} ->
              {[
                 %Runlet.Event{
                   event: %Runlet.Event.Ctrl{
                     service: "limit",
                     description:
                       "limit reached: new events will be dropped (#{limit} events/#{
                         seconds
                       } seconds)",
                     host: "#{node()}"
                   },
                   query: "limit #{limit} #{seconds}"
                 }
               ], false}

            {{:error, _}, false} ->
              {[], false}
          end
      end,
      fn _ ->
        ExRated.delete_bucket(name)
      end
    )
  end
end
