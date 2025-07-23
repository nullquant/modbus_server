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
    Logger.info("(#{__MODULE__}): GPIO starting")

    {_, 0} =
      System.cmd("gpio", [
        "mode",
        to_string(Application.get_env(:modbus_server, :gpio_stop_pin)),
        "in"
      ])

    {_, 0} =
      System.cmd("gpio", [
        "mode",
        to_string(Application.get_env(:modbus_server, :gpio_stop_pin)),
        "down"
      ])

    {_, 0} =
      System.cmd("gpio", [
        "mode",
        to_string(Application.get_env(:modbus_server, :gpio_fan_pin)),
        "out"
      ])

    {_, 0} =
      System.cmd("gpio", [
        "write",
        to_string(Application.get_env(:modbus_server, :gpio_fan_pin)),
        "0"
      ])

    Process.send_after(self(), :read, 1000)
    {:ok, ""}
  end

  @impl true
  def handle_info(:read, state) do
    # Logger.info("(#{__MODULE__}): Read GPIOs")
    read_gpio(state)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:write, pin, value}, state) do
    {_, 0} =
      System.cmd("gpio", ["write", to_string(pin), to_string(value)])

    {:noreply, state}
  end

  defp read_gpio(_state) do
    Process.send_after(self(), :read, 500)

    {result, 0} =
      System.cmd("gpio", ["read", to_string(Application.get_env(:modbus_server, :gpio_stop_pin))])

    {int_value, _} = Integer.parse(result)
    config_stop = Application.get_env(:modbus_server, :gpio_stop_on)

    stop =
      case int_value do
        config_stop -> 1
        _ -> 0
      end

    GenServer.cast(
      ModbusServer.EtsServer,
      {:set_integer, Application.get_env(:modbus_server, :gpio_stop_register), stop}
    )
  end
end
