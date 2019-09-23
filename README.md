# Runlet

A job command language for querying and enforcing flow control on
event streams. `runlet` is a library used for event notifications in
monitoring systems.

`runlets` are light weight processes connecting to an event source
similar to a shell pipeline. The output of a runlet can be temporarily
stopped or terminated using job control commands.

An event source could be a monitoring system like
[Riemann](http://riemann.io/) or the standard output of a containerized
system process.

The event stream is piped through commands to transform and rate limit
events before being outputted.

## Installation

Add runlet to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:runlet, git: "https://github.com/msantos/runlet.git"}]
end
```
