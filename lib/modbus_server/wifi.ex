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
    # Process.flag(:trap_exit, true)
    state = read_wifi()
    {:ok, state}
  end

  @impl true
  def handle_info(:read, _state) do
    Logger.info("(#{__MODULE__}): Read WiFi SSIDs")

    read_ip("eth0")
    state = read_wifi()
    Logger.info("(#{__MODULE__}): #{inspect(state)}")

    {:noreply, state}
  end

  defp read_wifi() do
    Process.send_after(self(), :read, 5000)

    # "-f active,SSID",
    {result, 0} = System.cmd("nmcli", ["-t", "device", "wifi"])

    Logger.info("(#{__MODULE__}): #{inspect(result)}")

    connected =
      result
      |> String.split("\n")
      |> Enum.filter(fn s -> String.at(s, 0) == "*" end)
      |> Enum.at(0)
      |> Enum.map(fn s -> s |> String.split(":") |> Enum.at(7) end)

    not_connected =
      result
      |> String.split("\n")
      |> Enum.filter(fn s -> String.at(s, 0) != "*" end)
      |> Enum.map(fn s -> s |> String.split(":") |> Enum.at(7) end)
      |> Enum.filter(fn s -> s != "" and s != nil end)
      |> Enum.uniq()

    {connected, not_connected}
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
