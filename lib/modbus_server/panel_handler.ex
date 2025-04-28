defmodule ModbusServer.PanelHandler do
  @moduledoc false

  require Logger
  use ThousandIsland.Handler

  @impl ThousandIsland.Handler
  def handle_data(data, socket, state) do
    case parse(data) do
      {:ok} ->
        nil

      {:error} ->
        Logger.info("(#{__MODULE__}): error while parsing #{inspect(data)}")

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

  defp parse_request(["w", "pv", value]) do
    {float_value, ""} = Float.parse(value)

    GenServer.cast(
      ModbusServer.EtsServer,
      {:set_float, 0, float_value}
    )

    {:ok}
  end

  defp parse_request(["w", "sp", value]) do
    {float_value, ""} = Float.parse(value)

    GenServer.cast(
      ModbusServer.EtsServer,
      {:set_float, 2, float_value}
    )

    {:ok}
  end

  defp parse_request(["w", "cloud_on", value]) do
    {int_value, ""} = Integer.parse(value)

    GenServer.cast(
      ModbusServer.EtsServer,
      {:set_integer, Application.get_env(:modbus_server, :cloud_on_register), int_value}
    )

    {:ok}
  end

  defp parse_request(["w", "fan", value]) do
    {int_value, ""} = Integer.parse(value)

    GenServer.cast(
      ModbusServer.EtsServer,
      {:set_integer, Application.get_env(:modbus_server, :gpio_fan_register), int_value}
    )

    GenServer.cast(
      ModbusServer.EtsServer,
      {:write, Application.get_env(:modbus_server, :gpio_fan_pin), int_value}
    )

    {:ok}
  end

  defp parse_request(["w", "id", value]) do
    GenServer.cast(
      ModbusServer.EtsServer,
      {:set_modbus_string, Application.get_env(:modbus_server, :cloud_id_register), value, 18}
    )

    {:ok}
  end

  defp parse_request(["w", "token", value]) do
    GenServer.cast(
      ModbusServer.EtsServer,
      {:set_modbus_string, Application.get_env(:modbus_server, :cloud_token_register), value, 16}
    )

    {:ok}
  end

  defp parse_request(["w", "ssid", value]) do
    GenServer.cast(
      ModbusServer.EtsServer,
      {:set_string, Application.get_env(:modbus_server, :wifi_ssid_register), value, 32}
    )

    {:ok}
  end

  defp parse_request(["w", "password", value]) do
    GenServer.cast(
      ModbusServer.EtsServer,
      {:set_string, Application.get_env(:modbus_server, :wifi_password_register), value, 16}
    )

    {:ok}
  end

  defp parse_request(["w", "wifi_on", value]) do
    {int_value, ""} = Integer.parse(value)

    GenServer.cast(
      ModbusServer.EtsServer,
      {:set_integer, Application.get_env(:modbus_server, :wifi_command_register), int_value}
    )

    {:ok}
  end

  defp parse_request(["r", "stop"]) do
    case GenServer.call(
           ModbusServer.EtsServer,
           {:read, Application.get_env(:modbus_server, :gpio_stop_register), 1}
         ) do
      {:error} -> {:error}
      {:reply, data} -> {:reply, List.to_string(data)}
    end
  end

  defp parse_request(["r", "ip"]) do
    case GenServer.call(
           ModbusServer.EtsServer,
           {:read, Application.get_env(:modbus_server, :wifi_ip_register), 16}
         ) do
      {:error} -> {:error}
      {:reply, data} -> {:reply, List.to_string(data)}
    end
  end

  defp parse_request(["r", what]) do
    address =
      case what do
        "ssid1" -> Application.get_env(:modbus_server, :wifi_ssid1_register)
        "ssid2" -> Application.get_env(:modbus_server, :wifi_ssid2_register)
        "ssid3" -> Application.get_env(:modbus_server, :wifi_ssid3_register)
        "ssid4" -> Application.get_env(:modbus_server, :wifi_ssid4_register)
        "ssid5" -> Application.get_env(:modbus_server, :wifi_ssid5_register)
        "ssid6" -> Application.get_env(:modbus_server, :wifi_ssid6_register)
        "ssid7" -> Application.get_env(:modbus_server, :wifi_ssid7_register)
        "ssid8" -> Application.get_env(:modbus_server, :wifi_ssid8_register)
      end

    case GenServer.call(
           ModbusServer.EtsServer,
           {:read, address, 32}
         ) do
      {:error} -> {:error}
      {:reply, data} -> {:reply, List.to_string(data)}
    end
  end
end
