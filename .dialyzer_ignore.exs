# lib/runlet/cmd/query.ex:98:no_return
# The created anonymous function has no local return.
# ________________________________________________________________________________
# lib/runlet/cmd/query.ex:112:pattern_match_cov
# The pattern
# variable_error
#
# can never match, because previous clauses completely cover the type
#
#   {:ok,
#    false
#    | nil
#    | true
#    | binary()
#    | [false | nil | true | binary() | [any()] | number() | map()]
#    | number()
#    | %{atom() | binary() => false | nil | true | binary() | [any()] | number() | map()}}
# .
#
# ________________________________________________________________________________
# lib/runlet/cmd/query.ex:197:no_return
# Function open/1 has no local return.
# ________________________________________________________________________________
# lib/runlet/cmd/query.ex:199:call
# The function call will not succeed.
#
# :gun.open(_host :: any(), _port :: any(), %{
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
# lib/runlet/cmd/query.ex:232:unused_fun
# Function get/1 will never be called.
# ________________________________________________________________________________
# lib/runlet/cmd/query.ex:333:unused_fun
# Function parse_error/2 will never be called.
# ________________________________________________________________________________
[
  # https://github.com/ninenines/gun/pull/242
  {"lib/runlet/cmd/query.ex", :call, 200},
  {"lib/runlet/cmd/query.ex", :no_return, 98},
  {"lib/runlet/cmd/query.ex", :no_return, 198},
  {"lib/runlet/cmd/query.ex", :unused_fun, 233},
  {"lib/runlet/cmd/query.ex", :unused_fun, 334}
]
