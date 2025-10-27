defmodule Orchestrator.MixProject do
  use Mix.Project

  def project do
    [
      app: :orchestrator,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Orchestrator.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 3.10"},
      {:ecto_sql, "~> 3.10"},
      {:ecto_sqlite3, "~> 0.19"},
      {:yaml_elixir, "~> 2.9"},
      {:libgraph, "~> 0.16"},
      {:phoenix, "~> 1.8"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_html_helpers, "~> 1.0"},
      {:phoenix_live_reload, "~> 1.4", only: :dev},
      {:plug_cowboy, "~> 2.7"},
      {:jason, "~> 1.4"},
      {:gettext, "~> 0.24"}
    ]
  end
end
