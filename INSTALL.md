
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


# Ethernet to WiFi
    git clone https://github.com/garywill/linux-router.git
    cd linux-router
    sudo lnxrouter -i eth0

# OrangePI Install

http://www.orangepi.org/orangepiwiki/index.php/Orange_Pi_Zero_3

### Install Erlang

    # ERLANG_VERSION=26.2
    add-apt-repository ppa:rabbitmq/rabbitmq-erlang
    apt update
    apt install -y -f erlang=1:26.2.5.9-1rmq1ppa1~ubuntu22.04.1

### Install Elixir

    ELIXIR_VERSION=1.18.3
    cd / && mkdir -p elixir && cd elixir && \
    wget -q https://github.com/elixir-lang/elixir/releases/download/v$ELIXIR_VERSION/elixir-otp-26.zip && \
    unzip elixir-otp-26.zip && \
    rm -f elixir-otp-26.zip && \
    ln -s /elixir/bin/elixirc /usr/local/bin/elixirc && \
    ln -s /elixir/bin/elixir /usr/local/bin/elixir && \
    ln -s /elixir/bin/mix /usr/local/bin/mix && \
    ln -s /elixir/bin/iex /usr/local/bin/iex

### Install local Elixir hex and rebar for the user

    su - orangepi -c '/usr/local/bin/mix local.hex --force && /usr/local/bin/mix local.rebar --force'

### Install lnxrouter

    cd ~
    git clone https://github.com/garywill/linux-router.git
    sudo nano /etc/rc.local

Add line (port 5900 for VNC):

    /home/orangepi/linux-router/lnxrouter -i eth0 -g 192.168.128.1 --tp 5900 --daemon

