#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting timezone...${NC}"
sudo timedatectl set-timezone Europe/Moscow

# Changing apt sources
echo -e "${GREEN}Changing apt sources...${NC}"
sudo rm /etc/apt/sources.list
sudo cat > nano /etc/apt/sources.list <<- "EOF"
deb http://mirrors.huaweicloud.com/debian bookworm main contrib non-free non-free-firmware
#deb http://repo.huaweicloud.com/debian bookworm main contrib non-free non-free-firmware
#deb-src http://repo.huaweicloud.com/debian bookworm main contrib non-free non-free-firmware

deb http://mirrors.huaweicloud.com/debian bookworm-updates main contrib non-free non-free-firmware
#deb http://repo.huaweicloud.com/debian bookworm-updates main contrib non-free non-free-firmware
#deb-src http://repo.huaweicloud.com/debian bookworm-updates main contrib non-free non-free-firmware

deb http://mirrors.huaweicloud.com/debian bookworm-backports main contrib non-free non-free-firmware
#deb http://repo.huaweicloud.com/debian bookworm-backports main contrib non-free non-free-firmware
#deb-src http://repo.huaweicloud.com/debian bookworm-backports main contrib non-free non-free-firmware
EOF

# Update the package lists
echo -e "${GREEN}Running apt update...${NC}"
sudo apt update

# Upgrade installed packages without prompting for confirmation
echo -e "${GREEN}Running apt upgrade...${NC}"
sudo apt upgrade -y

# Install Erlang 25
echo -e "${GREEN}Installing Erlang...${NC}"
sudo apt install git wget erlang iptables -y

# Perform a distribution upgrade, handling dependencies and removing obsolete packages
echo -e "${GREEN}Running apt dist-upgrade...${NC}"
sudo apt dist-upgrade -y

# Clean up unnecessary packages
echo -e "${GREEN}Cleaning up unnecessary packages...${NC}"
sudo apt autoremove -y
sudo apt clean

# Install Elixir 1.18.3
echo -e "${GREEN}Installing Elixir 1.18.3 / OTP 25...${NC}"
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
echo -e "${GREEN}Installing linux-router...${NC}"
cd /home/orangepi
git clone https://github.com/garywill/linux-router.git

# Install linux-router
echo -e "${GREEN}Installing modbus_server...${NC}"
git clone https://github.com/nullquant/modbus_server.git

# Add SSH host key
echo -e "${GREEN}Creating SSH host key...${NC}"
mkdir data
mkdir sftp_daemon
ssh-keygen -q -N "" -t rsa -f sftp_daemon/ssh_host_rsa_key

# Setup linux-router startup
echo -e "${GREEN}Setup linux-router startup...${NC}"
DEVICE=$(nmcli device | grep -E "eth0|end0" | cut -d ' ' -f 1)
sudo rm /etc/rc.local
sudo cat > /etc/rc.local <<- "EOF"
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

/home/orangepi/linux-router/lnxrouter -n -i $DEVICE -g 192.168.128.1 --no-dns --dhcp-dns 1.1.1.1

exit 0
EOF

# Setup WiFi and change time by any user
echo -e "${GREEN}Creating time policy...${NC}"
sudo cat > /etc/polkit-1/rules.d/10-timedate.rules <<- "EOF"
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.timedate1.set-time") {
        return polkit.Result.YES;
    }
});
EOF

echo -e "${GREEN}Creating wi-fi policy...${NC}"
sudo cat > /etc/polkit-1/rules.d/90-nmcli.rules <<- "EOF"
polkit.addRule(function(action, subject) {
    if (action.id.indexOf("org.freedesktop.NetworkManager.") == 0) {
         return polkit.Result.YES;
    }
});
EOF

# Add private config (CLOUD_HOST, CLOUD_PORT, CLOUD_ID, CLOUD_TOKEN, FTP_USER, FTP_PASSWORD):
if [ -f /home/orangepi/env ]; then
  echo -e "${GREEN}Add private config${NC}"
  cp /home/orangepi/env envs/.overrides.env
else
  echo -e "${GREEN}Can't find private config env file${NC}"
fi

# Compile
echo -e "${GREEN}Compile modbus_server${NC}"
cd modbus_server
mix deps.get
mix compile
mix release

git config --local core.hooksPath .githooks/

# Setup app startup
echo -e "${GREEN}Creating modbus_server service...${NC}"
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

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable modbus_server.service

# Setup periodic git pull
echo -e "${GREEN}Creating git pull service...${NC}"
sudo cat > /etc/systemd/system/git_pull.service <<- "EOF"
[Unit]
Description=Periodic git pull

[Service]
User=orangepi
Group=orangepi
Type=oneshot

WorkingDirectory=/home/orangepi/modbus_server

ExecStart=/usr/bin/git -C /home/orangepi/modbus_server pull
EOF

sudo cat > /etc/systemd/system/git_pull.timer <<- "EOF"
[Unit]
Description=Runs Periodic git pull

[Timer]
OnCalendar=*:0/10
Persistent=true
AccuracySec=1min

[Install]
WantedBy=timers.target
EOF

sudo echo "orangepi ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart modbus_server.service" >> /etc/sudoers

sudo systemctl daemon-reload
sudo systemctl enable git_pull.timer
sudo systemctl start git_pull.timer



echo -e "${GREEN}All done${NC}"
