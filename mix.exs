defmodule Jinx.MixProject do
  use Mix.Project

  def project do
    [
      app: :jinx,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.html": :test,
        "coveralls.json": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :observer, :wx, :runtime_tools],
      mod: {Jinx.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ecto, "~> 3.12.3"},
      {:excoveralls, "~> 0.10", only: :test},
      {:mix_audit, "~> 2.0", only: [:dev, :test], runtime: false},
      {:phoenix_pubsub, "~> 2.1"},
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false},
      {:styler, "~> 1.0", only: [:dev, :test], runtime: false},
      {:uxid, "~> 0.2.3"},
      {:y_ex, "~> 0.6.2"}
    ]
  end
end
