defmodule StreamTemporal.MixProject do
  use Mix.Project

  def project do
    [
      app: :stream_temporal,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:stream_data, "~> 1.0", optional: true}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp dialyzer do
    [
      flags: [
        :unmatched_returns,
        :error_handling,
        :underspecs,
        :overspecs,
        :missing_return,
        :extra_return
      ]
    ]
  end

  defp docs do
    [
      main: "StreamTemporal",
      extras: ["README.md": [title: "Overview"]]
    ]
  end
end
