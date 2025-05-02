defmodule ModbusServer.Supervisor do
  @moduledoc false

  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    eth0_ip = Modbus.Crc.get_ip(Application.get_env(:modbus_server, :eth0_iface))
    eth0_port = Application.get_env(:modbus_server, :eth0_port)

    eth0_ip_tuple =
      eth0_ip
      |> String.split(".")
      |> Enum.map(&String.to_integer/1)
      |> List.to_tuple()

    Logger.info("(#{__MODULE__}): Listening from panel on #{eth0_ip}:#{eth0_port} port")

    children = [
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
       port: eth0_port,
       handler_module: ModbusServer.PanelHandler,
       transport_options: [ip: eth0_ip_tuple]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
