defmodule MixLfeNew.MixProject do
  use Mix.Project

  def project do
    [
      app: :mix_lfe_new,
      version: "0.2.0",
      elixir: "~> 1.6",
      description: "A mix task for creating and setting up new LFE projects",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    []
  end
end
