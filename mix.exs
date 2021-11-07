defmodule Features.MixProject do
  use Mix.Project

  @github "https://github.com/danielefongo/features"
  @version "0.1.0"

  def project do
    [
      app: :features,
      description: "Enable or disable code using feature toggles",
      source_url: @github,
      version: @version,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: [
        links: %{"GitHub" => @github},
        licenses: ["GPL-3.0-or-later"]
      ],
      docs: [
        main: "readme",
        extras: ["README.md", "LICENSE"],
        source_ref: "v#{@version}",
        source_url: @github
      ]
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
      {:attributes, "~> 0.4.0"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
