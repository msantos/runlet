defmodule Runlet.Cmd.Runtime do
  @moduledoc "Output the bot uptime"

  @doc """
  Output the bot uptime.
  """
  @spec exec() :: Enumerable.t()
  def exec() do
    {up, _} = :erlang.statistics(:wall_clock)

    {days, {hours, minutes, seconds}} =
      :calendar.seconds_to_daystime(div(up, 1000))

    [
      %Runlet.Event{
        :event => %Runlet.Event.Stdout{
          service: "runtime",
          description:
            "#{days} days, #{hours} hours, #{minutes} minutes and #{seconds} seconds",
          host: "#{node()}"
        },
        :query => "runtime"
      }
    ]
  end
end
