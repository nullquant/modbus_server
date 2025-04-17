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
    {:ok, %{}}
  end

  @impl true
  def handle_info(:read, state) do
    Logger.info("(#{__MODULE__}): Read WiFi SSIDs")

    state = read_wifi(state)

    Logger.info("(#{__MODULE__}): Read WiFi SSIDs #{inspect(state)}")
    IO.puts("#{inspect(state)}")

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
        [] -> ""
        _ -> read_ip("wlan0")
      end

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
end
