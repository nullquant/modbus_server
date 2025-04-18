import Config
import Dotenvy

env_dir_prefix = System.get_env("RELEASE_ROOT") || Path.expand("./envs")

source!([
  Path.absname(".env", env_dir_prefix),
  Path.absname(".overrides.env", env_dir_prefix),
  Path.absname("#{config_env()}.env", env_dir_prefix),
  Path.absname("#{config_env()}.overrides.env", env_dir_prefix),
  System.get_env()
])

config :logger, :default_formatter, format: "$time [$level] $message\n"

config :logger, :default_handler,
  config: [
    file: ~c"modbus_server.log",
    filesync_repeat_interval: 5000,
    file_check: 5000,
    max_no_bytes: 10_000_000,
    max_no_files: 5,
    compress_on_rotate: true
  ]

config :modbus_server,
  password: env!("PASSWORD", :string),
  eth0_iface: env!("ETH0_IFACE", :string),
  eth0_port: env!("ETH0_PORT", :integer),
  cloud_host: env!("CLOUD_HOST", :string),
  cloud_port: env!("CLOUD_PORT", :integer),
  cloud_slave: env!("CLOUD_SLAVE", :integer),
  cloud_on_register: env!("CLOUD_ON_REGISTER", :integer),
  wifi_command_register: env!("WIFI_COMMAND_REGISTER", :integer),
  wifi_ip_register: env!("WIFI_IP_REGISTER", :integer),
  wifi_ssid_register: env!("WIFI_SSID_REGISTER", :integer),
  wifi_password_register: env!("WIFI_PASSWORD_REGISTER", :integer),
  wifi_ssid1_register: env!("WIFI_SSID1_REGISTER", :integer),
  wifi_ssid2_register: env!("WIFI_SSID2_REGISTER", :integer),
  wifi_ssid3_register: env!("WIFI_SSID3_REGISTER", :integer),
  wifi_ssid4_register: env!("WIFI_SSID4_REGISTER", :integer),
  wifi_ssid5_register: env!("WIFI_SSID5_REGISTER", :integer),
  wifi_ssid6_register: env!("WIFI_SSID6_REGISTER", :integer),
  wifi_ssid7_register: env!("WIFI_SSID7_REGISTER", :integer),
  wifi_ssid8_register: env!("WIFI_SSID8_REGISTER", :integer)
