defmodule ModbusServerTest do
  use ExUnit.Case
  doctest ModbusServer

  test "greets the world" do
    assert ModbusServer.hello() == :world
  end
end
