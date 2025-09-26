# MODBUS SERVER on OrangePI zero 3

### OrangePI Install

Manual: http://www.orangepi.org/orangepiwiki/index.php/Orange_Pi_Zero_3

Download image from http://www.orangepi.org/html/hardWare/computerAndMicrocontrollers/service-and-support/Orange-Pi-Zero-3.html

### Install bt script

wget https://github.com/nullquant/modbus_server/raw/refs/heads/main/install.sh
chmod +x install.sh
sudo ./install.sh


### Set timezone

    sudo timedatectl set-timezone Europe/Moscow

### Update

    sudo apt update
    sudo apt upgrade

### Install Erlang 25

    sudo apt install git wget erlang iptables

### Install Elixir 1.18.3

    cd /opt
    sudo mkdir elixir
    cd elixir
    sudo wget https://github.com/elixir-lang/elixir/releases/download/v1.18.3/elixir-otp-25.zip
    sudo unzip elixir-otp-25.zip
    sudo rm elixir-otp-25.zip
    sudo ln -s /opt/elixir/bin/elixirc /usr/local/bin/elixirc
    sudo ln -s /opt/elixir/bin/elixir /usr/local/bin/elixir
    sudo ln -s /opt/elixir/bin/mix /usr/local/bin/mix
    sudo ln -s /opt/elixir/bin/iex /usr/local/bin/iex

### Change password

    passwd

### Install lnxrouter

    cd ~
    git clone https://github.com/garywill/linux-router.git

### Install Modbus Server

    cd ~
    git clone https://github.com/nullquant/modbus_server.git

### Create data and sftp_daemon folders

    cd ~
    mkdir data
    mkdir sftp_daemon

### Add SSH host key:

    ssh-keygen -q -N "" -t rsa -f sftp_daemon/ssh_host_rsa_key

### Add private config (CLOUD_HOST, CLOUD_PORT, CLOUD_ID, CLOUD_TOKEN, FTP_USER, FTP_PASSWORD):

    cd modbus_server
    nano envs/.overrides.env

### Compile

    mix deps.get
    mix compile
    mix release

### Setup lnxrouter startup

    sudo nano /etc/rc.local

Add lines:

    # /home/orangepi/linux-router/lnxrouter -i end0 -o wlan0 -g 192.168.128.1 --no-dns --dhcp-dns 1.1.1.1
    /home/orangepi/linux-router/lnxrouter -n -i end0 -g 192.168.128.1 --no-dns --dhcp-dns 1.1.1.1

### Setup app startup

    sudo nano /etc/systemd/system/modbus_server.service

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

### Setup WiFi and change time by any user

    sudo nano /etc/polkit-1/rules.d/10-timedate.rules


polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.timedate1.set-time") {
        return polkit.Result.YES;
    }
});

    sudo nano /etc/polkit-1/rules.d/90-nmcli.rules

polkit.addRule(function(action, subject) {
    if (action.id.indexOf("org.freedesktop.NetworkManager.") == 0) {
         return polkit.Result.YES;
    }
});



 sudo nano /etc/sudoers


orangepi ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart modbus_server.service



### Raspberry PI

    sudo nano /usr/local/rtr-startup-script

#!/bin/sh -e
#

/home/pi/linux-router/lnxrouter -n -i end0 -g 192.168.128.1 --no-dns  --dhcp-dns 1.1.1.1

exit 0

    sudo chmod +x /usr/local/rtr-startup-script


    sudo nano /etc/systemd/system/rtr-startup.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/rtr-startup-script

[Install]
WantedBy=multi-user.target

    sudo systemctl enable rtr-startup.service





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
