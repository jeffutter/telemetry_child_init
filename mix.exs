defmodule TelemetryChildInit.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/jeffutter/telemetry_child_init"

  def project do
    [
      app: :telemetry_child_init,
      version: @version,
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "TelemetryChildInit",
      source_url: @source_url,
      description: description(),
      package: package(),
      docs: docs()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp description() do
    "Add telemetry events to your supervisors to track child startup times."
  end

  defp package() do
    [
      name: "telemetry_child_init",
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  def docs do
    [
      main: "TelemetryChildInit",
      source_ref: "v#{@version}",
      source_url: @source_url,
      api_reference: false,
      extra_section: []
    ]
  end

  defp deps do
    [
      {:telemetry, "~> 1.2.1"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
