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
    Logger.info("(#{__MODULE__}): Read GPIOs")
    read_gpio(state)
    {:noreply, state}
  end

  @impl true
  def handle_info({:write, pin, value}, state) do
    {_, 0} =
      System.cmd("gpio", ["write", to_string(pin), to_string(value)])

    {:noreply, state}
  end

  defp read_gpio(_state) do
    Process.send_after(self(), :read, 500)

    {result, 0} =
      System.cmd("gpio", ["read", to_string(Application.get_env(:modbus_server, :gpio_stop_pin))])

    {int_value, _} = Integer.parse(result)

    GenServer.cast(
      ModbusServer.EtsServer,
      {:set_modbus_string, Application.get_env(:modbus_server, :gpio_stop_register), int_value}
    )
  end
end
