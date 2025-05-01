defmodule ModbusServer.MixProject do
  use Mix.Project

  def project do
    [
      app: :modbus_server,
      version: "0.8.1",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:ssh, :logger],
      mod: {ModbusServer.Application, []}
    ]
  end

  defp releases do
    [
      modbus_server: [
        overlays: ["envs/"]
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dotenvy, "~> 1.0.0"},
      {:thousand_island, "~> 1.0"}
    ]
  end
end
