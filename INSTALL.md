# MODBUS SERVER on OrangePI zero 3

### OrangePI Install

Manual: http://www.orangepi.org/orangepiwiki/index.php/Orange_Pi_Zero_3

Download image from http://www.orangepi.org/html/hardWare/computerAndMicrocontrollers/service-and-support/Orange-Pi-Zero-3.html

### Update

    sudo add-apt-repository ppa:rabbitmq/rabbitmq-erlang
    sudo apt update
    sudo apt upgrade

### Install Erlang 26.2

    sudo apt install -y -f erlang=1:26.2.5.11-1rmq1ppa1~ubuntu22.04.1

### Install Elixir 1.18.3

    cd / 
    mkdir -p elixir 
    cd elixir 
    wget https://github.com/elixir-lang/elixir/releases/download/v1.18.3/elixir-otp-26.zip
    unzip elixir-otp-26.zip
    rm -f elixir-otp-26.zip
    ln -s /elixir/bin/elixirc /usr/local/bin/elixirc
    ln -s /elixir/bin/elixir /usr/local/bin/elixir
    ln -s /elixir/bin/mix /usr/local/bin/mix
    ln -s /elixir/bin/iex /usr/local/bin/iex

### Change password

    passwd

### Install lnxrouter

    cd ~
    git clone https://github.com/garywill/linux-router.git

### Install Modbus Server

    cd ~
    git clone https://github.com/nullquant/modbus_server.git

Add private config (CLOUD_HOST, CLOUD_PORT, CLOUD_ID, CLOUD_TOKEN, FTP_USER, FTP_PASSWORD):

    nano modbus_server/envs/.overrides.env

Add SSH host key:

    ssh-keygen -q -N "" -t rsa -f priv/sftp_daemon/ssh_host_rsa_key

Compile

    mix deps.get
    mix compile
    mix release

### Setup lnxrouter startup

    sudo nano /etc/rc.local

Add line:

    /home/orangepi/linux-router/lnxrouter -i eth0 -o wlan0 -g 192.168.128.1 --no-dns  --dhcp-dns 1.1.1.1

### Setup app startup

    sudo nano /lib/systemd/system/modbus_server.service

[Unit]
Description=PI server for Flexem Panel

[Service]
Type=simple
User=orangepi
Group=orangepi
Restart=on-failure
Environment=MIX_ENV=dev
Environment=LANG=en_US.UTF-8

WorkingDirectory=/home/orangepi/modbus_server

ExecStart=/home/orangepi/modbus_server/_build/dev/rel/modbus_server/bin/modbus_server start
ExecStop=/home/orangepi/modbus_server/_build/dev/rel/modbus_server/bin/modbus_server stop

[Install]
WantedBy=multi-user.target

    sudo systemctl enable modbus_server.service




Proxy port 5900 for VNC


# SNIFFER

### WiFi AP with Ethernet at eth0
    sudo create_ap -m nat wlan0 eth0 pipoint pi34wifi --no-virt --daemon

### find IP adresses of WiFi clients
    sudo more /tmp/create_ap.wlan0.conf.VpOpcZ7B/dnsmasq.leases

### Capture packets
    sudo tcpdump -i wlan0 host 192.168.12.170
    sudo tcpdump -A -i wlan0 host 192.168.12.170 -x

### Stop
    sudo create_ap --stop wlan0
