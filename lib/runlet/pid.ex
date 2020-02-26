defmodule Runlet.PID do
  @moduledoc "Conversion functions between Runlet and Erlang PIDs"

  use Bitwise

  @type t :: integer | float

  @doc ~S"""
  Convert a Elixir PID to a string

  ## Examples:

      iex> Runlet.PID.to_string(:erlang.list_to_pid('<0.1234.0>'))
      "1234"
      iex> Runlet.PID.to_string(:erlang.list_to_pid('<0.1234.56>'))
      "1234.56"
  """
  @spec to_string(pid) :: binary
  def to_string(pid) when is_pid(pid), do: parse("#{:erlang.pid_to_list(pid)}")

  @spec parse(binary) :: binary
  defp parse(pid) do
    [creation, num, serial] = Regex.split(~r/(\.|<|>)/, pid, trim: true)

    case {creation, num, serial} do
      {"0", _, "0"} -> num
      {"0", _, _} -> "#{num}.#{serial}"
    end
  end

  @doc ~S"""
  Convert an Elixir PID to a number

  ## Examples:

      iex> Runlet.PID.to_float(:erlang.list_to_pid('<0.1234.0>'))
      1234.0
      iex> Runlet.PID.to_float(:erlang.list_to_pid('<0.1234.56>'))
      1234.56
  """
  @spec to_float(pid | binary) :: float
  def to_float(pid) when is_pid(pid) do
    "#{:erlang.pid_to_list(pid)}" |> parse() |> to_float()
  end

  def to_float(pid) when is_binary(pid) do
    {n, _} = Float.parse(pid)
    n
  end

  @doc ~S"""
  Convert a representation of an Elixir PID.

  ## Examples:
    iex> Runlet.PID.to_pid(String.to_integer(Runlet.PID.to_string(:erlang.list_to_pid('<0.1234.0>'))))
    #PID<0.1234.0>
  """
  @spec to_pid(Runlet.PID.t() | pid | String.t() | charlist()) :: pid
  def to_pid(x) when is_pid(x), do: x
  def to_pid(x) when is_integer(x), do: :erlang.list_to_pid('<0.#{x}.0>')

  def to_pid(x) when is_float(x) do
    [num, serial] =
      x
      |> Float.to_string()
      |> String.split(".")

    :erlang.list_to_pid('<0.#{num}.#{serial}>')
  end

  def to_pid(x) when is_binary(x) do
    x
    |> String.to_charlist()
    |> :erlang.list_to_pid()
  end

  def to_pid(x) when is_list(x) do
    x
    |> :erlang.list_to_pid()
  end
end
