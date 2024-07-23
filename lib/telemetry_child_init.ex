defmodule TelemetryChildInit do
  @external_resource readme = "README.md"
  @moduledoc readme
             |> File.read!()
             |> String.split("<!--MDOC !-->")
             |> Enum.fetch!(1)

  def instrument(child_specs, supervisor_module) when is_list(child_specs) do
    telemetry_span_context = make_ref()
    atomic_ref = :atomics.new(1, [])

    updated =
      Enum.map(child_specs, &do_instrument(&1, supervisor_module, telemetry_span_context))

    [
      %{
        id: {supervisor_module, :telemetry_start},
        start:
          {TelemetryChildInit.Start, :init,
           [supervisor_module, telemetry_span_context, atomic_ref]},
        restart: :temporary,
        type: :worker
      }
      | updated
    ] ++
      [
        %{
          id: {supervisor_module, :telemetry_stop},
          start:
            {TelemetryChildInit.Stop, :init,
             [supervisor_module, telemetry_span_context, atomic_ref]},
          restart: :temporary,
          type: :worker
        }
      ]
  end

  defp do_instrument(%{start: _} = child_spec, supervisor_module, telemetry_span_context) do
    Map.update!(child_spec, :start, fn {m, f, a} ->
      {TelemetryChildInit, :init, [{m, f, a}, supervisor_module, telemetry_span_context]}
    end)
  end

  defp do_instrument({child_module, args}, supervisor_module, telemetry_span_context) do
    args
    |> child_module.child_spec()
    |> do_instrument(supervisor_module, telemetry_span_context)
  end

  defp do_instrument(child_module, supervisor_module, telemetry_span_context)
       when is_atom(child_module) do
    do_instrument({child_module, []}, supervisor_module, telemetry_span_context)
  end

  def init({m, f, a}, supervisor_module, telemetry_span_context) do
    metadata = %{
      telemetry_span_context: telemetry_span_context,
      supervisor_module: supervisor_module,
      module: m,
      function: f
    }

    res =
      :telemetry.span(
        [:supervisor, :child, :init],
        metadata,
        fn ->
          result = apply(m, f, a)
          {result, metadata}
        end
      )

    res
  end
end
