defmodule Runlet.Mixfile do
  use Mix.Project

  def project do
    [
      app: :runlet,
      version: "1.2.1",
      elixir: "~> 1.9",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description:
        "Job command language to query and flow control event streams",
      dialyzer: [
        list_unused_filters: true,
        flags: [
          :unmatched_returns,
          :error_handling,
          :race_conditions,
          :underspecs
        ]
      ],
      name: "runlet",
      source_url: "https://github.com/msantos/runlet",
      homepage_url: "https://github.com/msantos/runlet",
      docs: [
        main: "readme",
        source_ref: "master",
        extras: ["README.md"]
      ]
    ]
  end

  def application do
    [extra_applications: [:inets, :logger]]
  end

  defp deps do
    [
      {:gun, "~> 1.3"},
      {:poison, "~> 5.0"},
      {:vex, "~> 0.9.0"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.28", only: :dev, runtime: false}
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
