defmodule ModbusServer.PanelHandler do
  @moduledoc false

  require Logger
  use ThousandIsland.Handler

  @impl ThousandIsland.Handler
  def handle_data(data, socket, state) do
    # Logger.info("(#{__MODULE__}): got #{inspect(data)}")
    IO.puts("gets : #{inspect(data)}")
    ThousandIsland.Socket.send(socket, "\n")
    # ThousandIsland.Socket.send(socket, data)

    {:continue, state}
  end
end
