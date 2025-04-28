defmodule ModbusServer.Gpio do
  @moduledoc """
  Read and write GPIO.
  """
  use GenServer
  require Logger

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    Process.send_after(self(), :read, 1000)
    {:ok, %{connected: [], ssid: [], ip: ""}}
  end

  @impl true
  def handle_info(:read, state) do
    Logger.info("(#{__MODULE__}): Read GPIOs")
    read_gpio(state)
    {:noreply, state}
  end

  defp read_gpio(_state) do
    Process.send_after(self(), :read, 5000)

    {result, 0} =
      System.cmd("gpio", ["read", Application.get_env(:modbus_server, :gpio_stop_input)])

    {int_value, _} = Integer.parse(result)

    IO.puts("GPIO: #{inspect(int_value)}")
  end
end
