defmodule Runlet.Cmd.Fmt do
  @moduledoc "Format events"

  @doc """
  Formats JSON into output similar to syslog.
  """
  @spec exec(Enumerable.t()) :: Enumerable.t()
  def exec(stream) do
    startfun = fn -> true end

    transformfun = fn t, format ->
      f =
        receive do
          :runlet_fmt when format == true -> false
          :runlet_fmt when format == false -> true
        after
          0 -> format
        end

      e =
        case f do
          true ->
            case t do
              %Runlet.Event{} ->
                Runlet.Fmt.fmt(t.event)

              _ ->
                Runlet.Fmt.fmt(t)
            end

          false ->
            Runlet.Fmt.fmt(t)
        end
        |> URI.encode(&(&1 == 9 || &1 == 10 || (&1 >= 32 && &1 <= 126)))

      {[
         Enum.join(
           [
             "#{e}",
             t.attr
             |> Map.to_list()
             |> Enum.map(fn {_, v} -> Runlet.Fmt.fmt(v) end)
             |> Enum.join(" "),
             "#{Runlet.Fmt.fmt(self())}"
           ],
           " "
         )
       ], f}
    end

    endfun = fn _ -> nil end

    Stream.transform(
      stream,
      startfun,
      transformfun,
      endfun
    )
  end
end

require Runlet.Fmt

defimpl Runlet.Fmt, for: PID do
  def fmt(event) do
    pid = Runlet.PID.to_string(event)
    "<#{pid}>"
  end
end
