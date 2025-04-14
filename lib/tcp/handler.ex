defmodule Tcp.Handler do
  @moduledoc """
  A worker for each Modbus Client, handles Client requests.
  """
  use GenServer
  require Logger

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(args) do
    socket = Map.get(args, :socket)
    slave = Map.get(args, :slave)
    role = Map.get(args, :role)
    :inet.setopts(socket, active: true)
    {:ok, %{socket: socket, slave: slave, role: role}}
  end

  @impl true
  def handle_info({:tcp, socket, data}, %{slave: slave, role: role} = state) do
    Logger.info("(#{__MODULE__}): Received data: #{inspect(data, base: :hex)}")

    case Modbus.Tcp.parse(slave, role, data) do
      :none ->
        nil

      {_, response} ->
        :ok = :gen_tcp.send(socket, response)
    end

    {:noreply, state}
  end

  @impl true
  def handle_info({:tcp_closed, _socket}, state) do
    Logger.info("(#{__MODULE__}): Socket is closed")
    {:stop, {:shutdown, "Socket is closed"}, state}
  end

  @impl true
  def handle_info({:tcp_error, _socket, reason}, state) do
    Logger.error("(#{__MODULE__}): TCP error: #{inspect(reason)}")
    {:stop, {:shutdown, "TCP error: #{inspect(reason)}"}, state}
  end

  @impl true
  def handle_info(:timeout, state) do
    Logger.warning("(#{__MODULE__}): Timeout")
    :gen_tcp.close(state.socket)
    {:stop, {:normal, "TCP error: timout"}, state}
  end

  @impl true
  def terminate(:normal, _state), do: nil
end
