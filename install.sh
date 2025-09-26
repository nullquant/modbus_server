#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Setting timezone..."
sudo timedatectl set-timezone Europe/Moscow

# Update the package lists
echo "Running apt update..."
sudo apt update

# Upgrade installed packages without prompting for confirmation
echo "Running apt upgrade..."
sudo apt upgrade -y

# Install Erlang 25
echo "Installing Erlang..."
sudo apt install git wget erlang iptables -y

# Perform a distribution upgrade, handling dependencies and removing obsolete packages
echo "Running apt dist-upgrade..."
sudo apt dist-upgrade -y

# Clean up unnecessary packages
echo "Cleaning up unnecessary packages..."
sudo apt autoremove -y
sudo apt clean

# Install Elixir 1.18.3
echo "Installing Elixir 1.18.3 / OTP 25..."
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

# Install linux-router
echo "Installing linux-router..."
cd ~
git clone https://github.com/garywill/linux-router.git

# Install linux-router
echo "Installing modbus_server..."
git clone https://github.com/nullquant/modbus_server.git

# Add SSH host key
echo "Creating SSH host key..."
mkdir data
mkdir sftp_daemon
ssh-keygen -q -N "" -t rsa -f sftp_daemon/ssh_host_rsa_key

# Setup linux-router startup
echo "Setup linux-router startup..."
DEVICE=$(nmcli device | grep -E "eth0|end0" | cut -d ' ' -f 1)
echo "/home/orangepi/linux-router/lnxrouter -n -i $DEVICE -g 192.168.128.1 --no-dns --dhcp-dns 1.1.1.1" >> /etc/rc.local

# Setup WiFi and change time by any user
echo "Creating time policy..."
sudo cat > /etc/polkit-1/rules.d/10-timedate.rules <<- "EOF"
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.timedate1.set-time") {
        return polkit.Result.YES;
    }
});
EOF

echo "Creating wi-fi policy..."
sudo cat > /etc/polkit-1/rules.d/90-nmcli.rules <<- "EOF"
polkit.addRule(function(action, subject) {
    if (action.id.indexOf("org.freedesktop.NetworkManager.") == 0) {
         return polkit.Result.YES;
    }
});
EOF

# Add private config (CLOUD_HOST, CLOUD_PORT, CLOUD_ID, CLOUD_TOKEN, FTP_USER, FTP_PASSWORD):
if [ -f ~/env ]; then
  echo "Add private config"
  cp ~/env envs/.overrides.env
else
  echo "Can't find private config env file"
fi

# Compile
echo "Compile modbus_server"
cd modbus_server
mix deps.get
mix compile
mix release

# Setup app startup
echo "Creating modbus_server service..."
sudo cat > /etc/systemd/system/modbus_server.service <<- "EOF"
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
EOF

sudo systemctl enable modbus_server.service

echo "All done"
