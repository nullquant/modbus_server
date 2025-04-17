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

    {result, _} = System.cmd("nmcli", ["-t", "-f active,SSID", "device wifi"])

    result
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
