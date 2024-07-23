# TelemetryChildInit

<!--MDOC !-->

Add telemetry events to your supervisors to track child startup times.

## Installation

The package can be installed by adding `telemetry_child_init` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:telemetry_child_init, "~> 0.1.0"}
  ]
end
```

## Usage

### Instrument your supervisor:

```elixir
defmodule DummySupervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children =
      [{DummyChild, []}]
      |> TelemetryChildInit.instrument(__MODULE__)

    Supervisor.init(children, strategy: :one_for_one)
  end
end
```

### Collect telemetry events

```elixir
:telemetry_test.attach_event_handlers(self(), [
  [:supervisor, :startup, :start],
  [:supervisor, :startup, :stop],
  [:supervisor, :child, :init, :start],
  [:supervisor, :child, :init, :stop],
  [:supervisor, :child, :init, :exception]
])
```

## Telemetry Events

The following Events are emitted

* `[:supervisor, :startup, :start]` — before the first child is started
* `[:supervisor, :startup, :stop]` — after all children have been started
* `[:supervisor, :child, :init, :start]` — at the point the child's init call is called
* `[:supervisor, :child, :init, :stop]` — after the child's init call has completed
* `[:supervisor, :child, :init, :exception]` — when a child's init callback has had an exception

The following chart shows which metadata you can expect for each event:

| event                                      | measures                          | metadata                                                                                                           |
| ------------------------------------------ | --------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| `[:supervisor, :startup, :start]`          | `:system_time`, `:monotonic_time` | `:supervisor_module`, `:ref`                                                                                       |
| `[:supervisor, :startup, :stop]`           | `:duration`, `:monotonic_time`    | `:supervisor_module`, `:ref`                                                                                       |
| `[:supervisor, :child, :init, :start]`     | `:system_time`, `:monotonic_time` | `:telemetry_span_context`, `:supervisor_module`, `:ref`, `:module`                                                 |
| `[:supervisor, :child, :init, :stop]`      | `:duration`, `:monotonic_time`    | `:telemetry_span_context`, `:supervisor_module`, `:ref`, `:function`                                               |
| `[:supervisor, :child, :init, :exception]` | `:duration`, `:monotonic_time`    | `:telemetry_span_context`, `:supervisor_module`, `:ref`, `:module`, `:function`, `:kind`, `:reason`, `:stacktrace` |

### Metadata

* `:supervisor_module` — The module name for the supervisor itself
* `:telemetry_span_context` — A ref that corresponds to one instance of the supervisor, can be used to correlate start and stop events

For `:exception` events the metadata also includes details about what caused the failure. The
`:kind` value is determined by how an error occurred. Here are the possible kinds:

* `:error` — from an `{:error, error}` return value. Some Erlang functions may also throw an `:error` tuple, which will be reported as `:error`
* `:exit` — from a caught process exit
* `:throw` — from a caught value, this doesn't necessarily mean that an error occurred and the error value is unpredictable
