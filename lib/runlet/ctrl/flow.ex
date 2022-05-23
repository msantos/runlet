defmodule Runlet.Ctrl.Flow do
  @moduledoc "dynamically change flow control for a running event stream"

  @doc """
  Alters the flow control for a running process to 1/minute.
  """
  @spec exec(Runlet.t(), Runlet.PID.t()) :: Enumerable.t()
  def exec(%Runlet{uid: uid} = env, pid) do
    exec(env, pid, 1, 1, uid)
  end

  @doc """
  Alters the flow control for a running process or processes to count
  events in minutes:

      # pid 1234: 10 events/2 minutes
      flow 1234 10 2

      # pids 1234, 2345, 123456
      flow "1234 2345 12346" 10 2
  """
  @spec exec(Runlet.t(), Runlet.PID.t() | String.t(), pos_integer, pos_integer) ::
          Enumerable.t()
  def exec(%Runlet{uid: uid} = env, pid, count, minutes) do
    exec(env, pid, count, minutes, uid)
  end

  @doc """
  Alters the flow control for several processes running as a different
  user to count events in minutes.

      flow 1234 10 2 "nobody"
      flow "1234 2345 12346" 10 2 "nobody"
  """
  @spec exec(
          Runlet.t(),
          Runlet.PID.t() | String.t(),
          pos_integer,
          pos_integer,
          String.t()
        ) ::
          Enumerable.t()
  def exec(env, pid, count, minutes, uid) when is_binary(pid) do
    pid
    |> String.split()
    |> Enum.map(fn t -> Runlet.PID.to_float(t) end)
    |> Enum.map(fn t -> exec(env, t, count, minutes, uid) end)
  end

  def exec(_env, pid, count, minutes, uid)
      when is_integer(pid) or is_float(pid) do
    result = Runlet.Process.limit(uid, pid, count, minutes)

    [
      %Runlet.Event{
        event: %Runlet.Event.Ctrl{
          service: "flow",
          description: result,
          host: "#{node()}"
        },
        query: "flow #{pid} #{count} #{minutes} #{uid}"
      }
    ]
  end
end
