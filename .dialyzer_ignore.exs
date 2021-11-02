# lib/runlet/cmd/query.ex:96:no_return
# The created anonymous function has no local return.
# ________________________________________________________________________________
# lib/runlet/cmd/query.ex:207:no_return
# Function open/1 has no local return.
# ________________________________________________________________________________
# lib/runlet/cmd/query.ex:217:call
# The function call will not succeed.
#
# :gun.open(
#   string(),
#   _port :: any(),
#   _opt :: %{
#     :connect_timeout => _,
#     :http_opts => %{:content_handlers => [:gun_data_h | :gun_sse_h, ...]},
#     :protocols => [:http, ...],
#     :retry => 16_777_215,
#     :retry_timeout => _
#   }
# )
#
# breaks the contract
# (:inet.hostname() | :inet.ip_address(), :inet.port_number(), opts()) ::
#   {:ok, pid()} | {:error, any()}
#
# ________________________________________________________________________________
[
  # https://github.com/ninenines/gun/pull/242
  {"lib/runlet/cmd/query.ex", :call, 217},
  {"lib/runlet/cmd/query.ex", :no_return, 96},
  {"lib/runlet/cmd/query.ex", :no_return, 207}
]
