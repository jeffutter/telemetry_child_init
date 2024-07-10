defmodule TelemetryChildInitTest do
  use ExUnit.Case
  doctest TelemetryChildInit

  defmodule DummyChild do
    use GenServer

    def start_link(_) do
      GenServer.start_link(__MODULE__, [])
    end

    @impl true
    def init(_) do
      :timer.sleep(:timer.seconds(1))
      {:ok, %{}}
    end
  end

  defmodule DummySupervisor do
    use Supervisor

    def start_link(init_arg) do
      Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
    end

    @impl true
    def init(_init_arg) do
      children =
        [
          {DummyChild, []}
        ]
        |> TelemetryChildInit.instrument(__MODULE__)

      Supervisor.init(children, strategy: :one_for_one)
    end
  end

  test "emits telemetry events for supervisor children" do
    ref =
      :telemetry_test.attach_event_handlers(self(), [
        [:supervisor, :startup, :start],
        [:supervisor, :startup, :stop],
        [:supervisor, :child, :init, :start],
        [:supervisor, :child, :init, :stop],
        [:supervisor, :child, :init, :exception]
      ])

    {:ok, _pid} = start_supervised({DummySupervisor, []})

    assert_receive {[:supervisor, :startup, :start], ^ref, %{start: _},
                    %{supervisor_module: DummySupervisor, ref: super_ref}}

    assert_receive {[:supervisor, :child, :init, :start], ^ref, %{},
                    %{
                      supervisor_module: DummySupervisor,
                      module: DummyChild,
                      function: :start_link,
                      ref: ^super_ref
                    }}

    assert_receive {[:supervisor, :child, :init, :stop], ^ref, %{duration: child_duration},
                    %{
                      supervisor_module: DummySupervisor,
                      module: DummyChild,
                      function: :start_link,
                      ref: ^super_ref
                    }}

    assert child_duration >= 1000

    assert_receive {[:supervisor, :startup, :stop], ^ref,
                    %{stop: _, duration: supervisor_duration},
                    %{supervisor_module: DummySupervisor, ref: ^super_ref}}

    assert supervisor_duration >= 1000
  end
end
