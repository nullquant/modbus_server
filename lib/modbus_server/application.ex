defmodule ModbusServer.Application do
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    panel_ip = Modbus.Crc.get_ip(Application.get_env(:modbus_server, :eth0_iface))
    panel_port = Application.get_env(:modbus_server, :eth0_port)

    panel_ip_tuple =
      panel_ip
      |> String.split(".")
      |> Enum.map(&String.to_integer/1)
      |> List.to_tuple()

    ModbusServer.SFTPServer.start()

    Logger.info("(#{__MODULE__}): Listening from panel at #{panel_ip} on #{panel_port}")

    children = [
      %{
        id: ModbusServer.EtsServer,
        start: {ModbusServer.EtsServer, :start_link, [0]}
      },
      %{
        id: ModbusServer.CloudClient,
        start: {ModbusServer.CloudClient, :start_link, [0]}
      },
      %{
        id: ModbusServer.FileWriter,
        start: {ModbusServer.FileWriter, :start_link, [0]}
      },
      %{
        id: ModbusServer.Wifi,
        start: {ModbusServer.Wifi, :start_link, [0]}
      },
      %{
        id: ModbusServer.Gpio,
        start: {ModbusServer.Gpio, :start_link, [0]}
      },
      {ThousandIsland,
       port: panel_port,
       handler_module: ModbusServer.PanelHandler,
       transport_options: [ip: panel_ip_tuple]}
    ]

    opts = [strategy: :one_for_one, name: ModbusServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
