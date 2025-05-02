defmodule ModbusServer.Application do
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    ModbusServer.SFTPServer.start()

    children = [
      %{
        id: ModbusServer.EtsServer,
        start: {ModbusServer.EtsServer, :start_link, [0]}
      },
      %{
        id: ModbusServer.Supervisor,
        start: {ModbusServer.Supervisor, :start_link, [0]}
      },
      %{
        id: Proxy.Supervisor,
        start: {Proxy.Supervisor, :start_link, [0]}
      }
    ]

    opts = [strategy: :one_for_one, name: ModbusServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
