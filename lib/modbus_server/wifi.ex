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
    state = wifi_scan(state)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:set, value}, state) do
    # nmcli dev disconnect wlan0
    # nmcli dev wifi connect "XTTKmodel" password "xttk2019"
    # nmcli -w 10 dev wifi connect "NETGEAR L" password "abcdefgh"             ### timeout = 10 sec
    # nmcli exits with status 0 if it succeeds, a value greater than 0 is returned if an error occurs.

    # ssid_name = ssid_names[connect_read]
    # ssid_connected = ssid_name
    # command = 'nmcli -w 15 dev wifi connect "%s" password "%s"' % (ssid_name, password_value)
    {:reply, ssid_list} =
      GenServer.call(
        ModbusServer.EtsServer,
        {:read, Application.get_env(:modbus_server, :wifi_ssid_register), 32}
      )

    ssid =
      ssid_list
      |> List.to_string()
      |> String.trim()

    {:reply, password_list} =
      GenServer.call(
        ModbusServer.EtsServer,
        {:read, Application.get_env(:modbus_server, :wifi_password_register), 16}
      )

    password =
      password_list
      |> List.to_string()
      |> String.trim()

    case value do
      0 ->
        Logger.info("(#{__MODULE__}): Disconnect from WiFi")
        {result, res} = System.cmd("nmcli", ["device", "disconnect", "wlan0"])
        IO.puts("disconnect : #{inspect(result)} , #{inspect(res)}")

      _ ->
        Logger.info("(#{__MODULE__}): Connect to WiFi #{ssid} : #{password}")

        {result, res} =
          System.cmd("nmcli", [
            "-w",
            "15",
            "device",
            "wifi",
            "connect",
            "\"" <> ssid <> "\"",
            "password",
            "\"" <> password <> "\""
          ])

        IO.puts("connect : #{inspect(result)} , #{inspect(res)}")
    end

    {:noreply, state}
  end

  defp wifi_scan(state) do
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
          Modbus.Crc.get_ip("wlan0")
      end

    GenServer.cast(
      ModbusServer.EtsServer,
      {:set_string, Application.get_env(:modbus_server, :wifi_ip_register), ip, 16}
    )

    [connected | not_connected]
    |> List.flatten()
    |> Enum.uniq()
    |> Stream.concat(Stream.repeatedly(fn -> "" end))
    |> Enum.take(8)
    |> write_ssids()

    %{state | connected: connected, ssid: not_connected, ip: ip}
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
