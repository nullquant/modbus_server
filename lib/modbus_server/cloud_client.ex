defmodule ModbusServer.CloudClient do
  @moduledoc """
  Client that sends info into Cloud
  """
  use GenServer
  require Logger

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    Logger.info("(#{__MODULE__}): Cloud Client starting")

    Process.flag(:trap_exit, true)
    {:noreply, state} = check_flag(%{working: [0]})
    {:ok, state}
  end

  @impl true
  def handle_info({:tcp, socket, data}, %{slave: slave, role: role, processed: count} = state) do
    # Logger.info("(#{__MODULE__}): Received data: #{inspect(data, base: :hex)}")

    case Modbus.Tcp.parse(slave, role, data) do
      :none ->
        nil

      {_, response} ->
        :ok = :gen_tcp.send(socket, response)
    end

    new_count =
      if count > 999 do
        Logger.info("(#{__MODULE__}): Received #{inspect(count)} requests")
        0
      else
        count + 1
      end

    {:noreply, %{state | processed: new_count}}
  end

  @impl true
  def handle_info(:check_flag, state) do
    check_flag(state)
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
  def terminate(reason, %{socket: socket} = state) do
    Logger.info("Tcp.CloudClient: Shutdown  #{inspect(reason)}")
    :gen_tcp.close(socket)
    {:normal, state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.info("Tcp.CloudClient: Shutdown  #{inspect(reason)}")
    {:normal, state}
  end

  defp check_flag(%{working: working} = state) do
    Process.send_after(self(), :check_flag, 1000)

    case GenServer.call(
           ModbusServer.EtsServer,
           {:read, Application.get_env(:modbus_server, :cloud_on_register), 1}
         ) do
      ^working ->
        {:noreply, state}

      [0] ->
        {:stop, {:shutdown, "Cloud register is off"}, state}

      data ->
        {:ok, socket} =
          :gen_tcp.connect(
            String.to_charlist(Application.get_env(:modbus_server, :cloud_host)),
            Application.get_env(:modbus_server, :cloud_port),
            [:binary, {:packet, 0}]
          )

        Logger.info("(#{__MODULE__}): Connected to cloud server")

        {:noreply,
         %{
           working: data,
           socket: socket,
           slave: Application.get_env(:modbus_server, :cloud_slave),
           role: :read,
           processed: 0
         }}
    end
  end
end
