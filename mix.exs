defmodule PlugResponseCache.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :plug_response_cache,
      version: @version,
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      description: "A plug to cache an entire response.",
      package: package(),
      deps: deps(),
      docs: [
        extras: ["README.md"],
        main: "readme",
        source_ref: "v#{@version}",
        source_url: "https://github.com/sebastiandedeyne/plug_response_cache"
      ]
    ]
  end

  def application do
    [
      mod: {PlugResponseCache.Supervisor, []}
    ]
  end

  defp package do
    [
      name: :plug_response_cache,
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Sebastian De Deyne"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/sebastiandedeyne/plug_response_cache"}
    ]
  end

  defp deps do
    [
      {:plug, "~> 1.4.0"},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:dialyxir, "~> 0.5", only: :dev, runtime: false}
    ]
  end
end
