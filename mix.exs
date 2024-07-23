defmodule TelemetryChildInit.MixProject do
  use Mix.Project

  def project do
    [
      app: :telemetry_child_init,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "TelemetryChildInit",
      source_url: "https://github.com/jeffutter/telemetry_child_init",
      description: description(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [extra_applications: [:logger]]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [{:telemetry, "~> 1.2.1"}]
  end

  defp description() do
    "Add telemetry events to your supervisors to track child startup times."
  end

  defp package() do
    [
      name: "telemetry_child_init",
      files:
        ~w(lib priv .formatter.exs mix.exs README* readme* LICENSE* license* CHANGELOG* changelog* src),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/jeffutter/telemetry_child_init"}
    ]
  end
end
