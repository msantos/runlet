defmodule Runlet.Ctrl.Halt do
  @moduledoc "Shutdown the system"

  @doc """
  Requests the system to shut down.
  """
  @spec exec(Runlet.t()) :: Enumerable.t()
  def exec(env) do
    exec(env, 5)
  end

  @doc """
  Requests the system to shut down after the specified number of seconds:

    halt 10
  """
  @spec exec(Runlet.t(), pos_integer) :: Enumerable.t()
  def exec(env, 0) do
    exec(env, 1)
  end

  def exec(%Runlet{uid: uid}, seconds) do
    _ =
      :timer.apply_after(:timer.seconds(seconds), :"Elixir.System", :halt, [0])

    [
      %Runlet.Event{
        event: %Runlet.Event.Ctrl{
          service: "halt",
          description: "system halted by #{uid} in #{seconds} seconds",
          host: "#{node()}"
        },
        query: "halt #{uid} #{seconds}"
      }
    ]
  end
end
