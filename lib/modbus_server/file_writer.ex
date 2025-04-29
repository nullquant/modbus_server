defmodule ModbusServer.FileWriter do
  @moduledoc """
  Read and write data to files.
  """
  use GenServer
  require Logger

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    if not File.dir?("data") do
      File.mkdir("data")
    end

    {:ok, ""}
  end

  @impl true
  def handle_cast({:write}, state) do
    pv =
      GenServer.call(
        ModbusServer.EtsServer,
        {:get_float, 0}
      )

    sp =
      GenServer.call(
        ModbusServer.EtsServer,
        {:get_float, 2}
      )

    i1 =
      GenServer.call(
        ModbusServer.EtsServer,
        {:get_float, Application.get_env(:modbus_server, :i1_register)}
      )

    i2 =
      GenServer.call(
        ModbusServer.EtsServer,
        {:get_float, Application.get_env(:modbus_server, :i2_register)}
      )

    i3 =
      GenServer.call(
        ModbusServer.EtsServer,
        {:get_float, Application.get_env(:modbus_server, :i3_register)}
      )

    datetime = DateTime.to_string(DateTime.utc_now())

    data =
      String.slice(datetime, 0..18) <>
        "," <> pv <> "," <> sp <> "," <> i1 <> "," <> i2 <> "," <> i3 <> "\n"

    File.open("data/" <> String.slice(datetime, 0..9) <> ".csv", [:append])
    |> elem(1)
    |> IO.binwrite(data)

    {:noreply, state}
  end
end
