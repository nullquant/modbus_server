defmodule Tcp.Server do
  @moduledoc false

  use GenServer
  require Logger

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init({port, slave, role}) do
    Process.flag(:trap_exit, true)
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: 0, active: false, reuseaddr: true])
    Logger.info("Tcp.Server: Accepting connections on port #{port}")
    send(self(), :accept)
    {:ok, %{socket: socket, slave: slave, role: role}}
  end

  @impl true
  def handle_info(:accept, %{socket: socket, slave: slave, role: role} = state) do
    {:ok, client} = :gen_tcp.accept(socket)
    Logger.info("Tcp.Server: Accepted new connection")

    case DynamicSupervisor.start_child(Tcp.Handler.DynamicSupervisor, %{
           id: Tcp.Handler,
           start: {Tcp.Handler, :start_link, [%{socket: client, slave: slave, role: role}]},
           type: :worker
         }) do
      {:ok, pid} -> :gen_tcp.controlling_process(client, pid)
      {:error, reason} -> Logger.info("Tcp.Server: DynamicSupervisor error #{inspect(reason)}")
    end

    {:noreply, %{state | socket: socket}}
  end

  @impl true
  def terminate(reason, %{socket: socket} = state) do
    Logger.info("Tcp.Server: Shutdown  #{inspect(reason)}")
    :gen_tcp.close(socket)
    {:normal, state}
  end
end
