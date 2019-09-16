defmodule Runlet.History do
  @moduledoc "Runlet command history tracked by user"

  @type t :: {binary, any}

  @doc ~S"""
  Return the history for a user corresponding to a number or a list of numbers.
  """
  @spec lookup(binary, integer | [integer]) :: nil | t
  def lookup(user, index) when is_integer(index) do
    h = Runlet.State.table("history", user)
    Enum.at(h, index)
  end

  def lookup(user, index) when is_list(index) do
    h = Runlet.State.table("history", user)

    index
    |> Enum.map(fn t ->
      Enum.at(h, t)
    end)
    |> Enum.reject(fn t ->
      t == nil
    end)
    |> Enum.map(fn {k, _} -> k end)
  end

  @doc ~S"""
  Delete an item or items from a user's history.
  """
  @spec delete(binary, integer | [integer]) :: :ok | {:error, any}
  # XXX race condition
  def delete(user, index) when is_integer(index) do
    case lookup(user, index) do
      nil -> nil
      {k, _} -> Runlet.State.delete("history", user, k)
    end
  end

  def delete(user, index) when is_list(index) do
    h = Runlet.State.table("history", user)

    index
    |> Enum.map(fn t ->
      Enum.at(h, t)
    end)
    |> Enum.reject(fn t ->
      t == nil
    end)
    |> Enum.map(fn {k, _} -> k end)
    |> Enum.each(fn t ->
      Runlet.State.delete("history", user, t)
    end)
  end

  @doc ~S"""
  Complete history for a user.
  """
  @spec all(binary) :: [binary]
  def all(user) do
    "history"
    |> Runlet.State.table(user)
    |> dump()
  end

  defp dump(t), do: dump(t, [], 0)
  defp dump([], acc, _x), do: acc |> Enum.reverse()

  defp dump([{k, _v} | t], acc, x) do
    dump(t, ["#{x}: #{k}" | acc], x + 1)
  end

  @doc ~S"""
  Add an item into a user's history.
  """
  @spec add(binary, binary, any) :: :ok | {:error, any}
  def add(user, key, val) do
    Runlet.State.add("history", user, key, val)
  end
end
