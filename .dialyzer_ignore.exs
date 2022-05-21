# lib/runlet/cmd/query.ex:96:no_return
# The created anonymous function has no local return.
# ________________________________________________________________________________
# lib/runlet/cmd/query.ex:218:no_return
# Function open/1 has no local return.
# ________________________________________________________________________________
# lib/runlet/cmd/query.ex:227:call
# The function call will not succeed.
# 
# :gun.open(
#   string(),
#   _port :: any(),
#   _opt :: %{
#     :connect_timeout => _,
#     :http_opts => %{:content_handlers => [:gun_data_h | :gun_sse_h, ...]},
#     :protocols => [:http, ...],
#     :retry => 3,
#     :retry_timeout => _
#   }
# )
# 
# breaks the contract
# (:inet.hostname() | :inet.ip_address(), :inet.port_number(), opts()) ::
#   {:ok, pid()} | {:error, any()}
# 
# ________________________________________________________________________________
# lib/runlet/cmd/query.ex:374:call
# The function call will not succeed.
# 
# Poison.decode(_event :: any(), [{:as, struct()}, ...])
# 
# breaks the contract
# (iodata(), Poison.Decoder.options()) :: {:ok, Poison.Parser.t()} | {:error, Exception.t()}
# 
# ________________________________________________________________________________
# lib/runlet/cmd/query.ex:378:call
# The function call will not succeed.
# 
# Poison.decode(_event :: any(), [{:as, struct()}, ...])
# 
# breaks the contract
# (iodata(), Poison.Decoder.options()) :: {:ok, Poison.Parser.t()} | {:error, Exception.t()}
# 
# ________________________________________________________________________________
[
  # https://github.com/ninenines/gun/pull/242
  {"lib/runlet/cmd/query.ex", :call, 227},
  {"lib/runlet/cmd/query.ex", :no_return, 96},
  {"lib/runlet/cmd/query.ex", :no_return, 218},

  #  @typep as :: map | struct | [as]
  #
  #  @type options :: %{
  #              optional(:as) => as
  #            }
  {"lib/runlet/cmd/query.ex", :call, 374},
  {"lib/runlet/cmd/query.ex", :call, 378}
]
