defmodule ModbusServer.Ntp do
  use GenServer

  require Record
  require Logger

  @ntp_port 123
  @client_timeout 500

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl GenServer
  def init(_args) do
    state = get_time()
    {:ok, state}
  end

  def ntp_servers do
    ["0.ru.pool.ntp.org", "1.ru.pool.ntp.org", "2.ru.pool.ntp.org", "3.ru.pool.ntp.org"]
  end

  def get_time() do
    random_domain = Enum.random(ntp_servers())
    Logger.info("Selected NTP server name: #{inspect(random_domain)}")
    {:ok, {_, _, _, _, _, ips}} = :inet_res.getbyname(Enum.random(ntp_servers()), :a)
    Logger.info("Server IPs: #{inspect(ips)}")
    ip = Enum.random(ips)
    Logger.info("Selected server IP: #{inspect(ip)}")
    get_time(ip)
  end

  def get_time(ip) do
    ntp_request = create_ntp_request()
    {:ok, ntp_response} = send_ntp_request(ip, ntp_request)
    process_ntp_response(ntp_response)
  end

  def create_ntp_request do
    <<0::integer-size(2), 4::integer-size(3), 3::integer-size(3), 0::integer-size(376)>>
  end

  def send_ntp_request(ip, ntp_request) do
    {:ok, socket} = :gen_udp.open(0, [:binary, {:active, false}])
    Logger.info("Local socket: #{inspect(socket)}")
    :gen_udp.send(socket, ip, @ntp_port, ntp_request)
    {:ok, {_address, _port, response}} = :gen_udp.recv(socket, 0, @client_timeout)
    :gen_udp.close(socket)
    Logger.info("NTP server response: #{inspect(response)}")
    response
  end

  defp process_ntp_response(
         <<li::integer-size(2), version::integer-size(3), mode::integer-size(3),
           _rest::integer-size(376)>>
       ) do
    {li, version, mode}
  end
end
