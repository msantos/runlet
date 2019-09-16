ExUnit.start()

Application.put_env(
  :runlet,
  :statedir,
  Path.join([File.cwd!(), "priv", "test"])
)

File.rm_rf!(Path.join([File.cwd!(), "priv", "test"]))
Runlet.start_link()
