defmodule TelemetryChildInit.Stop do
  def init(supervisor_module, ref, atomic_ref) do
    stop_time = System.monotonic_time()
    start_time = :atomics.exchange(atomic_ref, 1, 0)
    :persistent_term.erase({TelemetryChildInit, supervisor_module, ref, :start})
    duration = System.convert_time_unit(stop_time - start_time, :native, :millisecond)

    :telemetry.execute([:supervisor, :startup, :stop], %{stop: stop_time, duration: duration}, %{
      supervisor_module: supervisor_module,
      ref: ref
    })

    :ignore
  end
end
