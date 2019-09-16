defmodule Runlet.Cmd.Dedup do
  @moduledoc "Deduplicate repeated events"

  @doc """
  Suppress repeated events in a stream:

    arg: "keys" "vals"

    example: "host service" "description"
  """
  @spec exec(Enumerable.t(), String.t(), String.t()) :: Enumerable.t()
  def exec(stream, key, val) do
    k =
      key
      |> String.split(" ", trim: true)
      |> Enum.map(fn t -> String.to_atom(t) end)

    v =
      val
      |> String.split(" ", trim: true)
      |> Enum.map(fn t -> String.to_atom(t) end)

    Stream.transform(
      stream,
      fn -> %{} end,
      fn
        %Runlet.Event{event: %Runlet.Event.Signal{}} = t, state ->
          {[t], state}

        %Runlet.Event{event: e} = t, state ->
          {match, _} = e |> Map.from_struct() |> Map.split(k)
          {content, _} = e |> Map.from_struct() |> Map.split(v)

          case Map.fetch(state, match) do
            {:ok, ^content} ->
              {[], state}

            {:ok, _} ->
              {[t], %{state | match => content}}

            :error ->
              {[t], Map.put(state, match, content)}
          end

        t, state when is_binary(t) ->
          {[t], state}
      end,
      fn _ ->
        :ok
      end
    )
  end
end
