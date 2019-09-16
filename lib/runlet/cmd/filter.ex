defmodule Runlet.Cmd.Filter do
  @moduledoc "Filter events based on a regular expression"

  @doc """
  Filter events using a regexp. The value of each JSON key is matched
  against the regexp.

  It may be more efficient to write a query. For example, instead
  of running:

      query 'service ~= "foo"' | filter "bar"

  Use:

      query 'service ~= "foo" and not description ~= "bar"'
  """
  @spec exec(Enumerable.t(), binary) :: Enumerable.t()
  def exec(stream, match) do
    startfun = fn -> Regex.compile!(match, [:caseless]) end

    transformfun = fn
      %Runlet.Event{event: %Runlet.Event.Signal{}} = t, re ->
        {[t], re}

      %Runlet.Event{event: e} = t, re ->
        case Runlet.Filter.proto(e, re) do
          true -> {[], re}
          false -> {[t], re}
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
end
