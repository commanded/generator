defmodule Commanded.Generator.MixProject do
  use Mix.Project

  @version "1.2.0"

  def project do
    [
      app: :commanded_generator,
      version: @version,
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.2"},
      {:floki, "~> 0.30"},
      {:tesla, "~> 1.4"}
    ]
  end
end
