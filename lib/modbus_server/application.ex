defmodule ModbusServer.Application do
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do

    Logger.info("(#{__MODULE__}): Application starting", Application.spec(:modbus_server, :vsn))

    ModbusServer.SFTPServer.start()

    children = [
      ModbusServer.Ntp,
      %{
        id: ModbusServer.EtsServer,
        start: {ModbusServer.EtsServer, :start_link, [0]}
      },
      ModbusServer.Supervisor,
      Proxy.Supervisor
    ]

    opts = [strategy: :one_for_one, name: ModbusServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
