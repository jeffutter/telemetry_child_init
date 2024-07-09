defmodule TelemetryChildInit.Stop do
  def init(module) do
    stop_time = System.monotonic_time()
    start_time = :persistent_term.get({TelemetryChildInit, module, :start})
    :persistent_term.erase({TelemetryChildInit, module, :start})
    duration = System.convert_time_unit(stop_time - start_time, :native, :millisecond)

    :telemetry.execute([:supervisor, :startup, :stop], %{stop: stop_time, duration: duration}, %{
      module: module
    })

    :ignore
  end
end
