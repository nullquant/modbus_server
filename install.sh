#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Setting timezone...${NC}"
sudo timedatectl set-timezone Europe/Moscow

# Update the package lists
echo -e "${BLUE}Running apt update...${NC}"
sudo apt update

# Upgrade installed packages without prompting for confirmation
echo -e "${BLUE}Running apt upgrade...${NC}"
sudo apt upgrade -y

# Install Erlang 25
echo -e "${BLUE}Installing Erlang...${NC}"
sudo apt install git wget erlang iptables -y

# Perform a distribution upgrade, handling dependencies and removing obsolete packages
echo -e "${BLUE}Running apt dist-upgrade...${NC}"
sudo apt dist-upgrade -y

# Clean up unnecessary packages
echo -e "${BLUE}Cleaning up unnecessary packages...${NC}"
sudo apt autoremove -y
sudo apt clean

# Install Elixir 1.18.3
echo -e "${BLUE}Installing Elixir 1.18.3 / OTP 25...${NC}"
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
echo -e "${BLUE}Installing linux-router...${NC}"
cd ~
git clone https://github.com/garywill/linux-router.git

# Install linux-router
echo -e "${BLUE}Installing modbus_server...${NC}"
git clone https://github.com/nullquant/modbus_server.git

# Add SSH host key
echo -e "${BLUE}Creating SSH host key...${NC}"
mkdir data
mkdir sftp_daemon
ssh-keygen -q -N "" -t rsa -f sftp_daemon/ssh_host_rsa_key

# Setup linux-router startup
echo -e "${BLUE}Setup linux-router startup...${NC}"
DEVICE=$(nmcli device | grep -E "eth0|end0" | cut -d ' ' -f 1)
sudo echo > /etc/rc.local <<- "EOF"
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

/home/orangepi/linux-router/lnxrouter -n -i eth0 -g 192.168.128.1 --no-dns --dhcp-dns 1.1.1.1

exit 0
EOF

# Setup WiFi and change time by any user
echo -e "${BLUE}Creating time policy...${NC}"
sudo echo > /etc/polkit-1/rules.d/10-timedate.rules <<- "EOF"
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.timedate1.set-time") {
        return polkit.Result.YES;
    }
});
EOF

echo -e "${BLUE}Creating wi-fi policy...${NC}"
sudo echo > /etc/polkit-1/rules.d/90-nmcli.rules <<- "EOF"
polkit.addRule(function(action, subject) {
    if (action.id.indexOf("org.freedesktop.NetworkManager.") == 0) {
         return polkit.Result.YES;
    }
});
EOF

# Add private config (CLOUD_HOST, CLOUD_PORT, CLOUD_ID, CLOUD_TOKEN, FTP_USER, FTP_PASSWORD):
if [ -f ~/env ]; then
  echo -e "${BLUE}Add private config${NC}"
  cp ~/env envs/.overrides.env
else
  echo -e "${BLUE}Can't find private config env file${NC}"
fi

# Compile
echo -e "${BLUE}Compile modbus_server${NC}"
cd modbus_server
mix deps.get
mix compile
mix release

# Setup app startup
echo -e "${BLUE}Creating modbus_server service...${NC}"
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

echo -e "${BLUE}All done${NC}"
