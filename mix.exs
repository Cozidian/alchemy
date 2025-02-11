defmodule ALCHEMY.MixProject do
  use Mix.Project

  def project do
    [
      app: :alchemy,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      config_path: "config/config.exs"
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ALCHEMY, []}
    ]
  end

  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:gen_stage, "~> 1.2.1"},
      {:httpoison, "~> 2.0"},
      {:jason, "~> 1.4"},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:pgvector, "~> 0.3.0"},
      {:file_system, "~> 1.0"}
    ]
  end
end
