defmodule MusicPrims.MixProject do
  use Mix.Project

  def project do
    [
      app: :music_prims,
      version: "0.2.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/bwanab/music_build"}
    ]
  end


  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false}
    ]
  end
end
