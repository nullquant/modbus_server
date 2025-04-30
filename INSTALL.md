# MODBUS SERVER

### OrangePI Install

Manual: http://www.orangepi.org/orangepiwiki/index.php/Orange_Pi_Zero_3

Download image from http://www.orangepi.org/html/hardWare/computerAndMicrocontrollers/service-and-support/Orange-Pi-Zero-3.html

### Update

    sudo add-apt-repository ppa:rabbitmq/rabbitmq-erlang
    sudo apt update
    sudo apt upgrade

### Install VSFTP

    sudo apt install vsftpd

### Install Erlang 26.2

    sudo apt install -y -f erlang=1:26.2.5.11-1rmq1ppa1~ubuntu22.04.1

### Install Elixir 1.18.3

    cd / 
    mkdir -p elixir 
    cd elixir 
    wget -q https://github.com/elixir-lang/elixir/releases/download/v1.18.3/elixir-otp-26.zip
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
    cd modbus_server/envs
    nano .overrides.env

Add config lines.

### Setup vsftp

    sudo useradd ftpuser
    sudo passwd ftpuser  
    sudo usermod ftpuser -s /sbin/nologin
    mkdir /home/orangepi/modbus_server/data
    sudo usermod ftpuser -d /home/orangepi/modbus_server/data/

ssh-keygen -q -N "" -t rsa -f priv/sftp_daemon/ssh_host_rsa_key

### Setup sturtup

    sudo nano /etc/rc.local

Add line:

    /home/orangepi/linux-router/lnxrouter -i eth0 -o wlan0 -g 192.168.128.1 --no-dns  --dhcp-dns 1.1.1.1
    /home/orangepi/modbus_server/_build/dev/rel/modbus_server/bin/modbus_server daemon


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
