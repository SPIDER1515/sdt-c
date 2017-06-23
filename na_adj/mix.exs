defmodule NA.Adj.Mixfile do
  use Mix.Project

  def project do
    [app: :na_adj,
     version: "0.1.0",
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [:logger, :na_db],
     mod: {NA.Adj, []},
     elixirc_paths: ["lib", "test/support"]]
  end

  defp deps do
    [
      {:na_db, in_umbrella: true},
      {:na_shared, in_umbrella: true},
      {:na_claims, in_umbrella: true}
    ]
  end
end
