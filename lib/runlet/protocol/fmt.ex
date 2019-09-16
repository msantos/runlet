defprotocol Runlet.Fmt do
  @fallback_to_any true
  @dialyzer {:nowarn_function, __protocol__: 1}
  def fmt(event)
end

defimpl Runlet.Fmt, for: Atom do
  def fmt(nil) do
    ""
  end

  def fmt(:null) do
    ""
  end

  def fmt(event) do
    "#{event}"
  end
end

defimpl Runlet.Fmt, for: Any do
  def fmt(event) when is_binary(event) do
    event
  end

  def fmt(event) do
    inspect(event)
  end
end
