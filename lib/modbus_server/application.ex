defmodule ModbusServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {DynamicSupervisor, name: Tcp.Handler.DynamicSupervisor, strategy: :one_for_one},
      %{
        id: Tcp.ServerWrite,
        start:
          {Tcp.Server, :start_link,
           [
             {Application.get_env(:owen_cloud, :eth0_port),
              Application.get_env(:owen_cloud, :eth0_slave), :write}
           ]}
      },
      # %{
      #  id: Tcp.ServerRead,
      #  start:
      #    {Tcp.Server, :start_link,
      #     [
      #       {Application.get_env(:owen_cloud, :owcl_port),
      #        Application.get_env(:owen_cloud, :owcl_slave), :read}
      #     ]}
      # },
      %{
        id: ModbusServer.EtsServer,
        start: {ModbusServer.EtsServer, :start_link, [0]}
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ModbusServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
