defmodule CliChat.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :cli_chat,
      name: "Simple CLI chat",
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      escript: escript(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {CliChat.Application, []}
    ]
  end

  defp escript do
    [main_module: CliChat.Application]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.29.1", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.2", only: [:dev, :test], runtime: false}
    ]
  end
end
