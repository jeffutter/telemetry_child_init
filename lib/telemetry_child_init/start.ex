defmodule TelemetryChildInit.Start do
  def init(module) do
    start_time = System.monotonic_time()
    :persistent_term.put({TelemetryChildInit, module, :start}, start_time)

    :telemetry.execute([:supervisor, :startup, :start], %{start: start_time}, %{module: module})

    :ignore
  end
end
