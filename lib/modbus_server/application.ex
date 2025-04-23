defmodule ModbusServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      %{
        id: ModbusServer.EtsServer,
        start: {ModbusServer.EtsServer, :start_link, [0]}
      },
      %{
        id: Tcp.CloudClient,
        start: {Tcp.CloudClient, :start_link, [0]}
      },
      %{
        id: ModbusServer.Wifi,
        start: {ModbusServer.Wifi, :start_link, [0]}
      },
      %{
        id: Tcp.DirectServer,
        start:
          {Tcp.DirectServer, :start_link,
           [
             {Application.get_env(:modbus_server, :eth0_iface),
              Application.get_env(:modbus_server, :eth0_port)}
           ]}
      },
      {DynamicSupervisor, name: Tcp.DirectHandler.DynamicSupervisor, strategy: :one_for_one}
    ]

    opts = [strategy: :one_for_one, name: ModbusServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
