defprotocol Runlet.Rate do
  @fallback_to_any true
  @dialyzer {:nowarn_function, __protocol__: 1}
  @spec rate(map | struct, %{count: integer}) :: %{count: integer}
  def rate(event, state)
end

defimpl Runlet.Rate, for: Any do
  @spec rate(map | struct, %{count: integer}) :: %{count: integer}
  def rate(_event, %{count: count} = state) do
    %{state | count: count + 1}
  end
end
