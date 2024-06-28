defmodule TelemetryChildInit do
  @moduledoc """
  Documentation for `TelemetryChildInit`.
  """

  def instrument(child_specs) when is_list(child_specs) do
    Enum.map(child_specs, &instrument/1)
  end

  def instrument({module, args}) do
    args
    |> module.child_spec()
    |> Map.update!(:start, fn {m, f, a} ->
      {TelemetryChildInit, :init, [{m, f, a}]}
    end)
  end

  def instrument(module) when is_atom(module) do
    instrument({module, []})
  end

  def init({m, f, a}) do
    metadata = %{module: m, function: f}

    res =
      :telemetry.span(
        [:worker, :processing],
        metadata,
        fn ->
          result = apply(m, f, a)
          {result, metadata}
        end
      )

    res
  end
end
