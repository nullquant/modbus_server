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

    files = File.ls!("data")

    if length(files) > Application.get_env(:modbus_server, :max_data_files) do
      files
      |> Enum.sort()
      |> Enum.take(length(files) - Application.get_env(:modbus_server, :max_data_files))
      |> Enum.map(fn x -> Path.join("data", x) end)
      |> Enum.map(fn x -> File.rm!(x) end)
    end

    {:ok, ""}
  end

  @impl true
  def handle_cast({:write}, state) do
    pv = to_string(GenServer.call(ModbusServer.EtsServer, {:get_float, 0}))
    sp = to_string(GenServer.call(ModbusServer.EtsServer, {:get_float, 2}))

    i1 =
      to_string(
        GenServer.call(
          ModbusServer.EtsServer,
          {:get_float, Application.get_env(:modbus_server, :i1_register)}
        )
      )

    i2 =
      to_string(
        GenServer.call(
          ModbusServer.EtsServer,
          {:get_float, Application.get_env(:modbus_server, :i2_register)}
        )
      )

    i3 =
      to_string(
        GenServer.call(
          ModbusServer.EtsServer,
          {:get_float, Application.get_env(:modbus_server, :i3_register)}
        )
      )

    datetime = DateTime.to_string(DateTime.add(DateTime.utc_now(), 3, :hour))

    data =
      String.slice(datetime, 0..22) <>
        "," <> pv <> "," <> sp <> "," <> i1 <> "," <> i2 <> "," <> i3 <> "\n"

    File.open("data/" <> String.slice(datetime, 0..9) <> ".csv", [:append])
    |> elem(1)
    |> IO.binwrite(data)

    {:noreply, state}
  end
end
