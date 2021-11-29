defmodule Runlet.Cmd.Grep do
  @moduledoc "Output events matching a regular expression"

  @doc """
  Select events using a regexp. The value of each JSON key is matched
  against the regexp.
  """
  @spec exec(Enumerable.t(), String.t()) :: Enumerable.t()
  def exec(stream, match) do
    startfun = fn -> Regex.compile!(match, [:caseless]) end

    transformfun = fn
      %Runlet.Event{event: %Runlet.Event.Signal{}} = t, re ->
        {[t], re}

      %Runlet.Event{event: e} = t, re ->
        case e
             |> to_bin()
             |> Enum.any?(&Regex.match?(re, &1)) do
          true -> {[t], re}
          false -> {[], re}
        end
    end

    endfun = fn _ ->
      nil
    end

    Stream.transform(
      stream,
      startfun,
      transformfun,
      endfun
    )
  end

  def to_bin(t) when is_map(t) do
    t
    |> Map.drop([:__struct__])
    |> Map.values()
    |> Enum.map(fn x -> to_bin(x) end)
    |> List.flatten()
    |> Enum.reject(fn
      "" -> true
      _ -> false
    end)
  end

  def to_bin(t) when t == nil or t == :null do
    ""
  end

  def to_bin(t) when is_binary(t) do
    t
  end

  def to_bin(t) do
    inspect(t)
  end
end
