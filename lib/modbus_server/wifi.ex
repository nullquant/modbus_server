defmodule ModbusServer.Wifi do
  @moduledoc """
  Read WiFi SSISs and store them in ETS.
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
    Logger.info("(#{__MODULE__}): Read WiFi SSIDs")
    state = read_wifi(state)
    {:noreply, state}
  end

  defp read_wifi(state) do
    Process.send_after(self(), :read, 5000)

    {result, 0} = System.cmd("nmcli", ["-t", "device", "wifi"])

    connected =
      result
      |> String.split("\n")
      |> Enum.filter(fn s -> String.at(s, 0) == "*" end)
      |> Enum.map(fn s -> s |> String.split(":") |> Enum.at(7) end)

    not_connected =
      result
      |> String.split("\n")
      |> Enum.filter(fn s -> String.at(s, 0) != "*" end)
      |> Enum.map(fn s -> s |> String.split(":") |> Enum.at(7) end)
      |> Enum.filter(fn s -> s != "" and s != nil end)
      |> Enum.uniq()

    ip =
      case connected do
        [] ->
          ""

        _ ->
          read_ip("wlan0")
      end

    GenServer.cast(
      ModbusServer.EtsServer,
      {:set_string, Application.get_env(:modbus_server, :wifi_ip_register), ip, 16}
    )

    [connected | not_connected]
    |> List.flatten()
    |> Stream.concat(Stream.repeatedly(fn -> "" end))
    |> Enum.take(8)
    |> write_ssids()

    %{state | connected: connected, ssid: not_connected, ip: ip}
  end

  defp read_ip(interface) do
    {result, _} = System.cmd("/sbin/ip", ["-o", "-4", "addr", "list", interface])

    result
    |> String.split(" ")
    |> Enum.at(6)
    |> String.split("/")
    |> Enum.at(0)
  end

  defp write_ssids([ssid1, ssid2, ssid3, ssid4, ssid5, ssid6, ssid7, ssid8]) do
    GenServer.cast(
      ModbusServer.EtsServer,
      {:set_string, Application.get_env(:modbus_server, :wifi_ssid1_register), ssid1, 16}
    )

    GenServer.cast(
      ModbusServer.EtsServer,
      {:set_string, Application.get_env(:modbus_server, :wifi_ssid2_register), ssid2, 16}
    )

    GenServer.cast(
      ModbusServer.EtsServer,
      {:set_string, Application.get_env(:modbus_server, :wifi_ssid3_register), ssid3, 16}
    )

    GenServer.cast(
      ModbusServer.EtsServer,
      {:set_string, Application.get_env(:modbus_server, :wifi_ssid4_register), ssid4, 16}
    )

    GenServer.cast(
      ModbusServer.EtsServer,
      {:set_string, Application.get_env(:modbus_server, :wifi_ssid5_register), ssid5, 16}
    )

    GenServer.cast(
      ModbusServer.EtsServer,
      {:set_string, Application.get_env(:modbus_server, :wifi_ssid6_register), ssid6, 16}
    )

    GenServer.cast(
      ModbusServer.EtsServer,
      {:set_string, Application.get_env(:modbus_server, :wifi_ssid7_register), ssid7, 16}
    )

    GenServer.cast(
      ModbusServer.EtsServer,
      {:set_string, Application.get_env(:modbus_server, :wifi_ssid8_register), ssid8, 16}
    )
  end
end
