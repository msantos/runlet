defmodule Runlet.Mixfile do
  use Mix.Project

  def project do
    [
      app: :runlet,
      version: "1.0.0",
      elixir: "~> 1.9",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description:
        "Job command language to query and flow control event streams",
      dialyzer: [
        plt_add_deps: :transitive,
        ignore_warnings: "dialyzer.ignore-warnings",
        paths: [
          "_build/dev/lib/runlet/ebin"
        ]
      ]
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [extra_applications: [:inets]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:ex_rated, "~> 1.3.1"},
      {:gun, "~> 1.3"},
      {:poison, "~> 3.1.0"},
      {:vex, "~> 0.6.0"},
      {:credo, "~> 0.9.1", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.6", only: [:dev], runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Michael Santos"],
      licenses: ["ISC"],
      links: %{github: "https://github.com/msantos/runlet"}
    ]
  end
end
