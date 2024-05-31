defmodule QuantumStoragePersistentMongodb.MixProject do
  use Mix.Project

  @version "1.0.3"

  def project do
    [
      app: :quantum_storage_mongodb,
      version: @version,
      elixir: "~> 1.14",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      name: "Quantum Storage Mongodb",
      description: "Quantum Storage Adapter based on Mongodb",
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.cobertura": :test
      ],
      build_embedded: (System.get_env("BUILD_EMBEDDED") || "false") in ["1", "true"]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    %{
      maintainers: [
        "Thanos Vassilakis"
      ],
      licenses: ["MIT"],
      exclude_patterns: [~r[priv/(tables|plts)]],
      links: %{
        "Changelog" =>
          "https://github.com/thanos/quantum-storage-mongodb/blob/master/CHANGELOG.md",
        "GitHub" => "https://github.com/thanos/quantum-storage-mongodb"
      }
    }
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: "https://github.com/thanos/quantum-storage-mongodb",
      extras: [
        "README.md"
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:mongodb_driver, "~> 1.4"},
      {:quantum, "~> 3.0"},
      {:mongodb_driver, "~> 1.4"},
      {:ex_doc, "~> 0.13", only: [:dev, :docs], runtime: false},
      {:excoveralls, "~> 0.13", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:mimic, "~> 1.7", only: :test}
    ]
  end
end
