# lib/runlet/cmd/query.ex:98:no_return The created anonymous function has no local return.
# lib/runlet/cmd/query.ex:112:pattern_match The pattern can never match the type
#   {:ok,
#    false
#    | nil
#    | true
#    | binary()
#    | [false | nil | true | binary() | [any()] | number() | map()]
#    | number()
#    | %{atom() | binary() => false | nil | true | binary() | [any()] | number() | map()}}
# .
# lib/runlet/cmd/query.ex:197:no_return Function open/1 has no local return.
# lib/runlet/cmd/query.ex:199:call The function call open will not succeed.
# lib/runlet/cmd/query.ex:232:unused_fun Function get/1 will never be called.
# lib/runlet/cmd/query.ex:333:unused_fun Function parse_error/2 will never be called.
[
	{"lib/runlet/cmd/query.ex", :no_return, 98},
  {"lib/runlet/cmd/query.ex", :pattern_match, 112},
	{"lib/runlet/cmd/query.ex", :no_return, 197},
	{"lib/runlet/cmd/query.ex", :call, 199},
	{"lib/runlet/cmd/query.ex", :unused_fun, 232},
	{"lib/runlet/cmd/query.ex", :unused_fun, 333},
]
