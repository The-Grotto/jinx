defmodule Jinx.MixProject do
  use Mix.Project

  def project do
    [
      app: :jinx,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_paths: ["lib"],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.html": :test,
        "coveralls.json": :test
      ]
    ]
  end

  def application do
    [
      mod: {Jinx.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ecto, "~> 3.12.3"},
      {:excoveralls, "~> 0.10", only: :test},
      {:mix_audit, "~> 2.0", only: [:dev, :test], runtime: false},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_pubsub, "~> 2.1"},
      {:postgrex, ">= 0.19.1"},
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false},
      {:styler, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end
end
