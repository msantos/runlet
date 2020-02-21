defmodule Runlet.Ctrl.HistoryUser do
  @moduledoc "View/run another user's history"

  @doc """
  View another user's history.
  """
  @spec exec(Runlet.t(), String.t()) :: Enumerable.t()
  def exec(%Runlet{} = env, uid) do
    [Runlet.State.path(), "#{Runlet.State.encode(uid)}*"]
    |> Path.join()
    |> Path.wildcard()
    |> Enum.map(fn
      [] ->
        []

      t ->
        x = t |> Path.split() |> Enum.at(-1) |> Runlet.State.decode()
        Runlet.Ctrl.History.exec(%{env | uid: x})
    end)
    |> List.flatten()
  end

  @doc """
  Run a command from another user's history.
  """
  @spec exec(Runlet.t(), String.t(), non_neg_integer) :: Enumerable.t()
  def exec(env, uid, index) do
    case [Runlet.State.path(), "#{Runlet.State.encode(uid)}*"]
         |> Path.join()
         |> Path.wildcard() do
      [] ->
        [
          %Runlet.Event{
            event: %Runlet.Event.Ctrl{
              service: "history",
              description: "history: no match: #{uid}",
              host: "#{node()}"
            },
            query: "history #{uid} #{index}"
          }
        ]

      [name] ->
        lookup(env, Path.basename(name), index)

      names ->
        n = names |> Enum.map(fn t -> Path.basename(t) end) |> Enum.join(", ")

        [
          %Runlet.Event{
            event: %Runlet.Event.Ctrl{
              service: "history",
              description: "history: multiple matches: #{n}",
              host: "#{node()}"
            },
            query: "history #{uid} #{index}"
          }
        ]
    end
  end

  defp lookup(%Runlet{pipeline: pipeline} = env, uid, index) do
    case Runlet.History.lookup(uid, index) do
      nil ->
        [
          %Runlet.Event{
            event: %Runlet.Event.Ctrl{
              service: "history",
              description: "history: invalid index: #{index}",
              host: "#{node()}"
            },
            query: "history #{uid} #{index}"
          }
        ]

      {cmd, _pid} ->
        procname =
          ~r/\s*\|\s*/
          |> Regex.split(pipeline, [:global, trim: true])
          |> Enum.drop(1)
          |> List.insert_at(0, cmd)
          |> Enum.join(" | ")

        _ = Runlet.Process.add(uid, self(), procname)

        Runlet.Ctrl.History.run(%{env | pipeline: cmd})
    end
  end
end
