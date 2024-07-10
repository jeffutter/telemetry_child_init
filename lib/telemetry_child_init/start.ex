defmodule TelemetryChildInit.Start do
  def init(supervisor_module, ref, atomic_ref) do
    start_time = System.monotonic_time()
    :atomics.put(atomic_ref, 1, start_time)

    :telemetry.execute([:supervisor, :startup, :start], %{start: start_time}, %{
      supervisor_module: supervisor_module,
      ref: ref
    })

    :ignore
  end
end
