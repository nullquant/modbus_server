defmodule ModbusServer.EtsServer do
  @moduledoc false

  use GenServer
  require Logger

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    table = :ets.new(:modbus_table, [:set, :protected, :named_table])

    # TRM500 registers
    # "PV"
    set_float(0, 20.0)
    # "SP"
    set_float(2, 0.0)
    # "SP2"
    set_float(4, 0.0)
    # "SumSP"
    set_float(6, 0.0)
    # "Hyst"
    set_float(8, 1.0)
    # "U.Lo"
    set_float(10, 10.0)
    # "U.Hi"
    set_float(12, 17.0)
    # "PPV"
    set_float(14, 0.0)
    # "inp.F"
    set_integer(16, 1)
    # "di.st"
    set_integer(17, 0)
    # "di.rc"
    set_integer(18, 1)
    # "ID"
    set_string(61572, "94606191032457742", 18)
    # "Token"
    set_string(61728, "GQ0ODHMO", 16)

    # Control registers
    # CLOUD_ON
    set_integer(Application.get_env(:modbus_server, :cloud_on_register), 0)
    # WiFi_Command
    set_integer(Application.get_env(:modbus_server, :wifi_command_register), 0)
    # WiFi_Status
    set_integer(Application.get_env(:modbus_server, :wifi_status_register), 0)
    # WiFi_SSID
    set_string(Application.get_env(:modbus_server, :wifi_ssid_register), "", 32)
    # WiFi_Password
    set_string(Application.get_env(:modbus_server, :wifi_password_register), "", 16)

    Logger.info("EtsServer: initialization")
    {:ok, %{data: table}}
  end

  @impl true
  def handle_cast({:write, write_request}, state) do
    {_, _, address, data, _} = write_request
    Logger.info("EtsServer: Write #{inspect(data)} to address #{address}")
    write_values(address, data)
    {:noreply, state}
  end

  @impl true
  def handle_call({:read, address, len}, _from, state) do
    # Logger.info("EtsServer: Read from address #{address}:#{len}")

    reply =
      case check_request(address, len) do
        true ->
          address_end = address + len - 1

          Enum.map(address..address_end, fn i ->
            [{_, value}] = :ets.lookup(:modbus_table, i)
            value
          end)

        false ->
          :error
      end

    {:reply, reply, state}
  end

  defp check_request(address, len) do
    address_end = address + len - 1

    Enum.all?(address..address_end, fn i ->
      :ets.lookup(:modbus_table, i) != []
    end)
  end

  # write list of values to registers
  defp write_values(address, values) do
    len = length(values)
    address_end = address + len

    ^address_end =
      Enum.reduce(values, address, fn value, i ->
        :ets.insert(:modbus_table, {i, value})
        i + 1
      end)
  end

  defp set_float(address, value) do
    [w0, w1] = Modbus.IEEE754.to_2_regs(value, :be)
    :ets.insert(:modbus_table, {address, w1})
    :ets.insert(:modbus_table, {address + 1, w0})
  end

  defp set_integer(address, value) do
    :ets.insert(:modbus_table, {address, value})
  end

  defp set_string(address, string, len) do
    values_list = string_to_values(string, len)
    write_values(address, values_list)
  end

  def string_to_values(string, length) do
    rotated = rotate_bytes([], to_charlist(string))

    rotated
    |> Enum.reverse()
    |> Stream.concat(Stream.repeatedly(fn -> 0 end))
    |> Enum.take(length)
  end

  defp rotate_bytes([], []) do
    []
  end

  defp rotate_bytes(list, [byte | []]) do
    <<value::16>> = <<0::8, byte::8>>
    [value | list]
  end

  defp rotate_bytes(list, [byte0, byte1 | []]) do
    <<value::16>> = <<byte1::8, byte0::8>>
    [value | list]
  end

  defp rotate_bytes(list, [byte0, byte1 | tail]) do
    <<value::16>> = <<byte1::8, byte0::8>>
    rotate_bytes([value | list], tail)
  end
end
