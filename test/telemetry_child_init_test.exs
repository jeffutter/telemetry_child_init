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
        |> TelemetryChildInit.instrument()

      Supervisor.init(children, strategy: :one_for_one)
    end
  end

  test "emits telemetry events for supervisor children" do
    ref =
      :telemetry_test.attach_event_handlers(self(), [
        [:worker, :processing, :start],
        [:worker, :processing, :stop],
        [:worker, :processing, :exception]
      ])

    start_supervised({DummySupervisor, []})

    assert_receive {[:worker, :processing, :start], ^ref, %{},
                    %{module: DummyChild, function: :start_link}}

    assert_receive {[:worker, :processing, :stop], ^ref, %{duration: _},
                    %{module: DummyChild, function: :start_link}}
  end
end
