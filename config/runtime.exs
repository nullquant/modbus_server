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
  eth0_port: env!("ETH0_PORT", :integer),
  eth0_slave: env!("ETH0_SLAVE", :integer),
  owcl_port: env!("CLOUD_HOST", :string),
  owcl_port: env!("CLOUD_PORT", :integer),
  owcl_slave: env!("CLOUD_SLAVE", :integer)
