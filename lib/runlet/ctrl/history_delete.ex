defmodule Runlet.Ctrl.HistoryDelete do
  @moduledoc "Delete items from history"

  @doc """
  Deletes items from the history:

      hd 4
      hd "1 2 4 6"
  """
  @spec exec(Runlet.t(), String.t() | integer) :: Enumerable.t()
  def exec(%Runlet{uid: uid}, index) when is_binary(index) do
    offset =
      index
      |> String.split()
      |> Enum.map(fn t -> String.to_integer(t) end)

    result = Runlet.History.delete(uid, offset)

    [
      %Runlet.Event{
        event: %Runlet.Event.Ctrl{
          service: "history delete",
          description: result,
          host: "#{node()}"
        },
        query: "history delete #{index} #{uid}"
      }
    ]
  end

  def exec(%Runlet{uid: uid}, index) when is_integer(index) do
    result = Runlet.History.delete(uid, index)

    [
      %Runlet.Event{
        event: %Runlet.Event.Ctrl{
          service: "history delete",
          description: result,
          host: "#{node()}"
        },
        query: "history delete #{index} #{uid}"
      }
    ]
  end
end
