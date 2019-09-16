defprotocol Runlet.Filter do
  @fallback_to_any true
  @dialyzer {:nowarn_function, __protocol__: 1}
  def proto(event, re)
end

defimpl Runlet.Filter, for: Any do
  def proto(event, re) do
    event
    |> to_bin()
    |> Enum.any?(fn x -> Regex.match?(re, x) end)
  end

  defp to_bin(t) when is_map(t) do
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

  defp to_bin(t) when t == nil or t == :null do
    ""
  end

  defp to_bin(t) when is_binary(t) do
    t
  end

  defp to_bin(t) do
    inspect(t)
  end
end
