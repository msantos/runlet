defmodule Runlet.Ctrl.Ps do
  @moduledoc "List running processes"

  @doc """
  List running processes.
  """
  @spec exec(Runlet.t()) :: Enumerable.t()
  def exec(%Runlet{uid: uid} = env), do: exec(env, uid)

  @doc """
  List a user's running processes.
  """
  @spec exec(Runlet.t(), String.t()) :: Enumerable.t()
  def exec(env, "-a") do
    Runlet.Process.table()
    |> Enum.map(fn uid -> exec(env, uid) end)
    |> List.flatten()
  end

  def exec(_env, uid) do
    uid
    |> Runlet.Process.all()
    |> Enum.chunk_every(20, 20)
    |> Enum.map(fn t -> Enum.join(t, "\n\n") end)
    |> Enum.map(fn t ->
      %Runlet.Event{
        event: %Runlet.Event.Ctrl{
          service: "ps",
          description: "#{uid}:\n#{t}",
          host: "#{node()}"
        },
        query: "ps #{uid}"
      }
    end)
  end
end
