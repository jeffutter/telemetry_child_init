defmodule TelemetryChildInit do
  @moduledoc """
  Documentation for `TelemetryChildInit`.
  """

  def instrument(child_specs, module) when is_list(child_specs) do
    updated =
      Enum.map(child_specs, &instrument/1)

    [
      %{
        id: {module, :telemetry_start},
        start: {TelemetryChildInit.Start, :init, [module]},
        restart: :temporary,
        type: :worker
      }
      | updated
    ] ++
      [
        %{
          id: {module, :telemetry_stop},
          start: {TelemetryChildInit.Stop, :init, [module]},
          restart: :temporary,
          type: :worker
        }
      ]
  end

  def instrument(%{start: _} = child_spec) do
    Map.update!(child_spec, :start, fn {m, f, a} ->
      {TelemetryChildInit, :init, [{m, f, a}]}
    end)
  end

  def instrument({module, args}) do
    args
    |> module.child_spec()
    |> instrument()
  end

  def instrument(module) when is_atom(module) do
    instrument({module, []})
  end

  def init({m, f, a}) do
    metadata = %{module: m, function: f}

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
