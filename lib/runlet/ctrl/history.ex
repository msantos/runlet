defmodule Runlet.Ctrl.History do
  @moduledoc "List and run items from command history"

  @doc """
  List command history.
  """
  @spec exec(Runlet.t()) :: Enumerable.t()
  def exec(%Runlet{uid: uid}) do
    uid
    |> Runlet.History.all()
    |> Enum.chunk_every(20, 20)
    |> Enum.map(fn t -> Enum.join(t, "\n\n") end)
    |> Enum.map(fn t ->
      %Runlet.Event{
        event: %Runlet.Event.Ctrl{
          service: "history",
          description: "#{uid}:\n#{t}",
          host: "#{node()}"
        },
        query: "history #{uid}"
      }
    end)
  end

  @doc """
  Run commands from history:

    args: 10
    args: "10 11 34"
  """
  @spec exec(Runlet.t(), non_neg_integer | String.t()) :: Enumerable.t()
  def exec(%Runlet{} = env, index) when is_binary(index) do
    index
    |> String.split()
    |> Enum.map(fn t -> exec(env, String.to_integer(t)) end)
  end

  def exec(%Runlet{uid: uid, pipeline: pipeline} = env, index)
      when is_integer(index) do
    case Runlet.History.lookup(uid, index) do
      nil ->
        [
          %Runlet.Event{
            event: %Runlet.Event.Ctrl{
              service: "history",
              description: "history: invalid index: #{index}",
              host: "#{node()}"
            },
            query: "history #{index}"
          }
        ]

      {cmd, _pid} ->
        procname =
          ~r/\s*\|\s*/
          |> Regex.split(pipeline, [:global, trim: true])
          |> Enum.drop(1)
          |> List.insert_at(0, cmd)
          |> Enum.join(" | ")

        run(%{env | pipeline: procname})
    end
  end

  @spec run(Runlet.t()) :: Enumerable.t()
  def run(%Runlet{pipeline: pipeline} = env) do
    case Runlet.fork(env) do
      {:ok, pid} ->
        [
          %Runlet.Event{
            event: %Runlet.Event.Ctrl{
              service: "history",
              description:
                "history: #{pipeline}: PID #{Runlet.PID.to_string(pid)}"
            },
            query: "history"
          }
        ]

      {:error, error} ->
        [
          %Runlet.Event{
            event: %Runlet.Event.Ctrl{
              service: "history",
              description: "#{error}"
            },
            query: "history"
          }
        ]
    end
  end
end
