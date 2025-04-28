defmodule ModbusServer.PanelHandler do
  @moduledoc false

  require Logger
  use ThousandIsland.Handler

  @impl ThousandIsland.Handler
  def handle_data(data, socket, state) do
    # Logger.info("(#{__MODULE__}): got #{inspect(data)}")
    case parse(data) do
      {:ok} ->
        nil

      {:reply, :error} ->
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

  defp parse_request(["r", "ip"]) do
    {:reply,
     GenServer.call(
       ModbusServer.EtsServer,
       {:read, Application.get_env(:modbus_server, :wifi_ip_register), 16}
     )}
  end
end
