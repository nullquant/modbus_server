defmodule Tcp.DirectServer do
  @moduledoc false

  use GenServer
  require Logger

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init({interface, port}) do
    Process.flag(:trap_exit, true)
    ip = Modbus.Crc.get_ip(interface)

    Logger.info("Tcp.DirectServer: Accepting connections on ip #{ip}")

    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: 0, active: false, reuseaddr: true, ip: ip])

    Logger.info("Tcp.DirectServer: Accepting connections on port #{port}")
    send(self(), :accept)
    {:ok, %{socket: socket, ip: ip}}
  end

  @impl true
  def handle_info(:accept, %{socket: socket, ip: _ip} = state) do
    {:ok, _client} = :gen_tcp.accept(socket)
    Logger.info("Tcp.DirectServer: Accepted new connection")

    # case DynamicSupervisor.start_child(Tcp.Handler.DynamicSupervisor, %{
    #       id: Tcp.Handler,
    #       start: {Tcp.Handler, :start_link, [%{socket: client, slave: slave, role: role}]},
    #       type: :worker
    #     }) do
    #  {:ok, pid} -> :gen_tcp.controlling_process(client, pid)
    #  {:error, reason} -> Logger.info("Tcp.Server: DynamicSupervisor error #{inspect(reason)}")
    # end

    # {:noreply, %{state | socket: socket}}
    {:stop, {:normal, "TCP error: out"}, state}
  end

  @impl true
  def terminate(reason, %{socket: socket} = state) do
    Logger.info("Tcp.DirectServer: Shutdown  #{inspect(reason)}")
    :gen_tcp.close(socket)
    {:normal, state}
  end
end
