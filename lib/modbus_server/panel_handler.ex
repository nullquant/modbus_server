defmodule ModbusServer.PanelHandler do
  @moduledoc false

  require Logger
  use ThousandIsland.Handler

  @impl ThousandIsland.Handler
  def handle_data(data, socket, state) do
    case parse(data) do
      {:ok} ->
        nil

      {:reply, reply} ->
        ThousandIsland.Socket.send(socket, reply)
    end

    {:continue, state}
  end

  def parse(data) do
    data
    |> String.downcase()
    |> String.split(",")
    |> parse_request()
  end

  defp parse_request(["data", pv, sp, i1, i2, i3]) do
    {pv_float, ""} = Float.parse(pv)
    {sp_float, ""} = Float.parse(sp)
    {i1_float, ""} = Float.parse(i1)
    {i2_float, ""} = Float.parse(i2)
    {i3_float, ""} = Float.parse(i3)

    GenServer.cast(
      ModbusServer.EtsServer,
      {:set_float, 0, pv_float}
    )

    GenServer.cast(
      ModbusServer.EtsServer,
      {:set_float, 2, sp_float}
    )

    GenServer.cast(
      ModbusServer.EtsServer,
      {:set_float, Application.get_env(:modbus_server, :i1_register), i1_float}
    )

    GenServer.cast(
      ModbusServer.EtsServer,
      {:set_float, Application.get_env(:modbus_server, :i2_register), i2_float}
    )

    GenServer.cast(
      ModbusServer.EtsServer,
      {:set_float, Application.get_env(:modbus_server, :i3_register), i3_float}
    )

    GenServer.cast(ModbusServer.FileWriter, {:write})

    {:ok}
  end

  defp parse_request(["w", "fan", value]) do
    {int_value, ""} = Integer.parse(value)

    GenServer.cast(
      ModbusServer.EtsServer,
      {:set_integer, Application.get_env(:modbus_server, :gpio_fan_register), int_value}
    )

    GenServer.cast(
      ModbusServer.Gpio,
      {:write, Application.get_env(:modbus_server, :gpio_fan_pin), int_value}
    )

    {:ok}
  end

  defp parse_request(["cloud", id, token, value]) do
    GenServer.cast(
      ModbusServer.EtsServer,
      {:set_modbus_string, Application.get_env(:modbus_server, :cloud_id_register), id, 18}
    )

    GenServer.cast(
      ModbusServer.EtsServer,
      {:set_modbus_string, Application.get_env(:modbus_server, :cloud_token_register), token, 16}
    )

    {int_value, ""} = Integer.parse(value)

    GenServer.cast(
      ModbusServer.EtsServer,
      {:set_integer, Application.get_env(:modbus_server, :cloud_on_register), int_value}
    )

    {:ok}
  end

  defp parse_request(["r", "ssids"]) do
    ssids =
      [
        Application.get_env(:modbus_server, :wifi_ssid1_register),
        Application.get_env(:modbus_server, :wifi_ssid2_register),
        Application.get_env(:modbus_server, :wifi_ssid3_register),
        Application.get_env(:modbus_server, :wifi_ssid4_register),
        Application.get_env(:modbus_server, :wifi_ssid5_register),
        Application.get_env(:modbus_server, :wifi_ssid6_register),
        Application.get_env(:modbus_server, :wifi_ssid7_register),
        Application.get_env(:modbus_server, :wifi_ssid8_register)
      ]
      |> Enum.map(fn address ->
        GenServer.call(ModbusServer.EtsServer, {:read, address, 32}) |> List.to_string()
      end)
      |> Enum.join("")

    error =
      GenServer.call(
        ModbusServer.EtsServer,
        {:read, Application.get_env(:modbus_server, :wifi_error_register), 1}
      )

    GenServer.cast(
      ModbusServer.EtsServer,
      {:set_integer, Application.get_env(:modbus_server, :wifi_error_register), 0}
    )

    stop =
      GenServer.call(
        ModbusServer.EtsServer,
        {:read, Application.get_env(:modbus_server, :gpio_stop_register), 1}
      )

    {:reply,
     ssids <>
       (GenServer.call(
          ModbusServer.EtsServer,
          {:read, Application.get_env(:modbus_server, :wifi_ip_register), 16}
        )
        |> List.to_string()) <> to_string(error) <> to_string(stop)}
  end

  defp parse_request(["disconnect"]) do
    GenServer.cast(ModbusServer.Wifi, {:disconnect})
    {:ok}
  end

  defp parse_request(["connect", ssid, password]) do
    GenServer.cast(ModbusServer.Wifi, {:connect, ssid, password})
    {:ok}
  end
end
