# lib/runlet/cmd/query.ex:94:no_return
# The created anonymous function has no local return.
# ________________________________________________________________________________
# lib/runlet/cmd/query.ex:194:no_return
# Function open/1 has no local return.
# ________________________________________________________________________________
# lib/runlet/cmd/query.ex:196:call
# The function call will not succeed.
#
# :gun.open(string(), _port :: any(), %{
#   :connect_timeout => _,
#   :http_opts => %{:content_handlers => [:gun_data_h | :gun_sse_h, ...]},
#   :protocols => [:http, ...],
#   :retry => 16_777_215,
#   :retry_timeout => _
# })
#
# breaks the contract
# (:inet.hostname() | :inet.ip_address(), :inet.port_number(), opts()) ::
#   {:ok, pid()} | {:error, any()}
#
# ________________________________________________________________________________
# lib/runlet/cmd/query.ex:229:unused_fun
# Function get/1 will never be called.
# ________________________________________________________________________________
# lib/runlet/cmd/query.ex:334:unused_fun
# Function parse_error/2 will never be called.
# ________________________________________________________________________________
[
  # https://github.com/ninenines/gun/pull/242
  {"lib/runlet/cmd/query.ex", :call, 196},
  {"lib/runlet/cmd/query.ex", :no_return, 94},
  {"lib/runlet/cmd/query.ex", :no_return, 194},
  {"lib/runlet/cmd/query.ex", :unused_fun, 229},
  {"lib/runlet/cmd/query.ex", :unused_fun, 334}
]
