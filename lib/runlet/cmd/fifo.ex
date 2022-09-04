defmodule Runlet.Cmd.Fifo do
  @moduledoc "Create a named fifo as the input to a runlet"

  @doc """
  Use a named fifo for runlet input.

  Creates a fifo. One or more runlets can send events to the fifo. If
  the fifo does not exist, events are discarded.

      fifo foo
      runtime > foo
  """
  @spec exec(String.t()) :: Enumerable.t()
  def exec(name) do
    registered =
      try do
        Process.register(self(), String.to_atom(name))
      rescue
        _ ->
          false
      end

    case registered do
      true ->
        stdin(name)

      false ->
        [
          %Runlet.Event{
            :event => %Runlet.Event.Stdout{
              service: name,
              description: "fifo not available",
              host: "#{node()}"
            },
            :query => "fifo #{name}"
          }
        ]
    end
  end

  defp stdin(name) do
    resourcefun = fn state ->
      receive do
        {:runlet_stdin, t} ->
          {[
             %Runlet.Event{
               :event => t,
               :query => "fifo #{name}"
             }
           ], state}

        :runlet_exit ->
          {:halt, state}
      end
    end

    Stream.resource(
      fn -> :ok end,
      resourcefun,
      fn _ -> :ok end
    )
  end
end
