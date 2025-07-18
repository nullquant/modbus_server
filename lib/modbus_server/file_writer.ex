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
    Logger.info("(#{__MODULE__}): File Writer starting")

    data_folder =
      Path.join(:code.priv_dir(:modbus_server), Application.get_env(:modbus_server, :ftp_folder))

    if not File.dir?(data_folder) do
      File.mkdir(data_folder)
    end

    files = File.ls!(data_folder)

    if length(files) > Application.get_env(:modbus_server, :max_data_files) do
      files
      |> Enum.sort()
      |> Enum.take(length(files) - Application.get_env(:modbus_server, :max_data_files))
      |> Enum.map(fn x -> Path.join(data_folder, x) end)
      |> Enum.map(fn x -> File.rm!(x) end)
    end

    {:ok, %{folder: data_folder, writed: 0}}
  end

  @impl true
  def handle_cast({:write}, %{folder: data_folder, writed: count} = state) do
    pv = to_string(GenServer.call(ModbusServer.EtsServer, {:get_float, 0}))
    sp = to_string(GenServer.call(ModbusServer.EtsServer, {:get_float, 2}))
    out = to_string(GenServer.call(ModbusServer.EtsServer, {:get_float, 14}))
    [s1v] = GenServer.call(ModbusServer.EtsServer, {:read, 16, 1})
    s1 = to_string(s1v)
    [s2v] = GenServer.call(ModbusServer.EtsServer, {:read, 17, 1})
    s2 = to_string(s2v)

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

    fan =
      to_string(
        GenServer.call(
          ModbusServer.EtsServer,
          {:get_float, Application.get_env(:modbus_server, :fan_register)}
        )
      )

    datetime = DateTime.to_string(DateTime.add(DateTime.utc_now(), 3, :hour))

    data = [
      String.slice(datetime, 0..22),
      ",",
      pv,
      ",",
      sp,
      ",",
      i1,
      ",",
      i2,
      ",",
      i3,
      ",",
      fan,
      ",",
      out,
      ",",
      s1,
      ",",
      s2,
      "\n"
    ]

    File.open(Path.join(data_folder, String.slice(datetime, 0..9) <> ".csv"), [:append])
    |> elem(1)
    |> IO.binwrite(data)

    new_count =
      if count > 999 do
        Logger.info("(#{__MODULE__}): Writed #{inspect(count)} lines")
        0
      else
        count + 1
      end

    {:noreply, %{state | writed: new_count}}
  end
end
