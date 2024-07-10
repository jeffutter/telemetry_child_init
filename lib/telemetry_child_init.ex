defmodule TelemetryChildInit do
  @moduledoc """
  Documentation for `TelemetryChildInit`.
  """

  def instrument(child_specs, supervisor_module) when is_list(child_specs) do
    ref = make_ref()
    atomic_ref = :atomics.new(1, [])

    updated =
      Enum.map(child_specs, &do_instrument(&1, supervisor_module, ref))

    [
      %{
        id: {supervisor_module, :telemetry_start},
        start: {TelemetryChildInit.Start, :init, [supervisor_module, ref, atomic_ref]},
        restart: :temporary,
        type: :worker
      }
      | updated
    ] ++
      [
        %{
          id: {supervisor_module, :telemetry_stop},
          start: {TelemetryChildInit.Stop, :init, [supervisor_module, ref, atomic_ref]},
          restart: :temporary,
          type: :worker
        }
      ]
  end

  defp do_instrument(%{start: _} = child_spec, supervisor_module, ref) do
    Map.update!(child_spec, :start, fn {m, f, a} ->
      {TelemetryChildInit, :init, [{m, f, a}, supervisor_module, ref]}
    end)
  end

  defp do_instrument({child_module, args}, supervisor_module, ref) do
    args
    |> child_module.child_spec()
    |> do_instrument(supervisor_module, ref)
  end

  defp do_instrument(child_module, supervisor_module, ref) when is_atom(child_module) do
    do_instrument({child_module, []}, supervisor_module, ref)
  end

  def init({m, f, a}, supervisor_module, ref) do
    metadata = %{supervisor_module: supervisor_module, module: m, function: f, ref: ref}

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
