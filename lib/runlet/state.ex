defmodule Runlet.State do
  @moduledoc "Persistent state storage for processes"

  @doc """
  Storage location for runlet state.
  """
  @spec path() :: binary
  def path() do
    Runlet.Config.get(
      :runlet,
      :statedir,
      Path.join([File.cwd!(), "priv/state"])
    )
  end

  @doc """
  Characters escaped by percent encoding. Allows @.
  """
  @spec char_reserved?(byte) :: boolean
  def char_reserved?(char) do
    char == ?@ or not URI.char_reserved?(char)
  end

  @doc """
  Percent encode identifier in a filesystem safe format.
  """
  @spec encode(binary) :: binary
  def encode(user) do
    URI.encode(user, &char_reserved?/1)
  end

  @doc """
  Decode identifier from percent encoding.
  """
  @spec decode(binary) :: binary
  def decode(user) do
    URI.decode(user)
  end

  @doc """
  Test if a state dir for a user exists.
  """
  @spec exists?(String.t()) :: boolean
  def exists?(id) do
    user = encode(id)
    File.exists?(Path.join([path(), user]))
  end

  @doc """
  Test if a given state file exists for a user.
  """
  @spec exists?(String.t(), String.t()) :: boolean
  def exists?(type, id) do
    user = encode(id)
    File.exists?(Path.join([path(), user, type]))
  end

  @spec open(binary, String.t(), String.t()) :: {:ok, atom} | {:error, any}
  defp open(dir, type, id) do
    open(dir, type, id, :read_write)
  end

  @spec open(binary, String.t(), String.t(), :read | :read_write) ::
          {:ok, atom} | {:error, any}
  defp open(dir, type, id, access) do
    user = encode(id)
    table = :erlang.binary_to_atom("#{type}_#{user}", :latin1)
    dirname = Path.join([dir, user])
    File.mkdir_p!(dirname)
    filename = [dirname, type] |> Path.join() |> String.to_charlist()
    :dets.open_file(table, type: :set, file: filename, access: access)
  end

  @doc """
  Lists all entries in a state file for a user.
  """
  @spec table(String.t(), String.t()) :: [tuple]
  def table(type, id) do
    user = encode(id)
    table(path(), type, user)
  end

  @spec table(binary, String.t(), String.t()) :: [tuple]
  def table(dir, type, id) do
    user = encode(id)

    case open(dir, type, user, :read) do
      {:ok, db} ->
        r = :dets.foldl(fn x, a -> [x | a] end, [], db)
        _ = :dets.close(db)
        r

      {:error, {:file_error, _, :enoent}} ->
        []
    end
  end

  @doc """
  Remove key in user's state file.
  """
  @spec delete(String.t(), String.t(), any) :: :ok | {:error, any}
  def delete(type, id, key) do
    user = encode(id)
    delete(path(), type, user, key)
  end

  def delete(dir, type, id, key) do
    user = encode(id)
    {:ok, db} = open(dir, type, user)
    r = :dets.delete(db, key)
    _ = :dets.close(db)
    r
  end

  @doc """
  Add key/value to user state file.
  """
  @spec add(String.t(), String.t(), any, any) :: :ok | {:error, any}
  def add(type, id, key, val) do
    user = encode(id)
    add(path(), type, user, key, val)
  end

  def add(dir, type, id, key, val) do
    user = encode(id)
    {:ok, db} = open(dir, type, user)
    r = :dets.insert(db, {key, val})
    _ = :dets.close(db)
    r
  end
end
