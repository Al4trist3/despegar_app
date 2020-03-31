defmodule DespegarApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :despegar_app,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      
      # Docs
      name: "Despegar App",
      source_url: "https://github.com/Al4trist3/despegar_app",
      homepage_url: "https://github.com/Al4trist3/despegar_app",
      docs: [
        main: "Despegar_app.WSTaxLogger", # The main page in the docs
        logo: "/home/alatriste/Pictures/alex.png",
        extras: ["README.md"]
        ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :httpoison]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:httpoison, "~> 1.6"},
      {:jason, "~> 1.2"},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
    ]
  end
end
