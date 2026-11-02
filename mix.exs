defmodule Hermetica.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source "https://github.com/hermeticacomms/hermetica-elixir"

  def project do
    [
      app: :hermetica,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Elixir client for the Hermetica API: one function per operation, idempotency keys, retries, cursor paging.",
      package: [name: "hermeticacomms", licenses: ["MIT"], links: %{"GitHub" => @source}],
      docs: [main: "readme", extras: ["README.md"], source_ref: "v#{@version}", source_url: @source]
    ]
  end

  def application, do: [extra_applications: [:logger]]

  defp deps do
    [
      {:req, "~> 0.5"},
      {:plug, "~> 1.16", only: :test},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end
end
