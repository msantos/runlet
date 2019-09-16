# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure for your application as:
#
#     config :runlet, key: :value
#
# And access this configuration in your application as:
#
#     Application.get_env(:runlet, :key)
#
# Or configure a 3rd-party app:
#
#     config :logger, level: :info
#
config :runlet,
  riemann_host: "localhost",
  riemann_port: "8080",
  riemann_url: "/event/index?query=",
  statedir: "priv/state",
  aliases: [
    {"exit", {[:Runlet, :Ctrl, :Exit], :exec}},
    {"h", {[:Runlet, :Ctrl, :History], :exec}},
    {"H", {[:Runlet, :Ctrl, :HistoryUser], :exec}},
    {"help", {[:Runlet, :Ctrl, :Help], :exec}},
    {"he", {[:Runlet, :Ctrl, :Help], :exec}},
    {"hd", {[:Runlet, :Ctrl, :HistoryDelete], :exec}},
    {"kill", {[:Runlet, :Ctrl, :Kill], :exec}},
    {"ps", {[:Runlet, :Ctrl, :Ps], :exec}},
    {"reflow", {[:Runlet, :Ctrl, :Flow], :exec}},
    {"refmt", {[:Runlet, :Ctrl, :Fmt], :exec}},
    {"start", {[:Runlet, :Ctrl, :Start], :exec}},
    {"stop", {[:Runlet, :Ctrl, :Stop], :exec}},
    {"hup", {[:Runlet, :Ctrl, :Signal], :exec}},
    {"signal", {[:Runlet, :Ctrl, :Signal], :exec}},
    {"halt", {[:Runlet, :Ctrl, :Halt], :exec}},
    {"query",
     [
       {[:Runlet, :Cmd, :Query], :exec},
       {{[:Runlet, :Cmd, :Valve], :exec}, []},
       {{[:Runlet, :Cmd, :Flow], :exec}, [20, 100]}
     ]},
    {~S(\query),
     [
       {[:Runlet, :Cmd, :Query], :exec}
     ]},
    {"runtime", {[:Runlet, :Cmd, :Runtime], :exec}},
    {"abort", {[:Runlet, :Cmd, :Abort], :exec}},
    {"dedup", {[:Runlet, :Cmd, :Dedup], :exec}},
    {"flow", {[:Runlet, :Cmd, :Flow], :exec}},
    {"fmt", {[:Runlet, :Cmd, :Fmt], :exec}},
    {"grep", {[:Runlet, :Cmd, :Grep], :exec}},
    {"limit", {[:Runlet, :Cmd, :Limit], :exec}},
    {"over", {[:Runlet, :Cmd, :Threshold], :exec}},
    {"rate", {[:Runlet, :Cmd, :Rate], :exec}},
    {"select", {[:Runlet, :Cmd, :Select], :exec}},
    {"stdin", {[:Runlet, :Cmd, :Stdin], :exec}},
    {"suppress", {[:Runlet, :Cmd, :Suppress], :exec}},
    {"take", {[:Runlet, :Cmd, :Take], :exec}},
    {"threshold", {[:Runlet, :Cmd, :Threshold], :exec}},
    {"timeout", {[:Runlet, :Cmd, :Timeout], :exec}},
    {"valve", {[:Runlet, :Cmd, :Valve], :exec}},
    {">", {[:Runlet, :Cmd, :Stdin], :exec}}
  ],
  riemann_event: [
    Runlet.Event.Riemann
  ]

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"
