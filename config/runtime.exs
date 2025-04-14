import Config
import Dotenvy

env_dir_prefix = System.get_env("RELEASE_ROOT") || Path.expand("./envs")

source!([
  Path.absname(".env", env_dir_prefix),
  Path.absname("#{config_env()}.env", env_dir_prefix),
  System.get_env()
])

config :logger, :default_formatter, format: "$time [$level] $message\n"

config :logger, :default_handler,
  config: [
    file: ~c"owen_cloud.log",
    filesync_repeat_interval: 5000,
    file_check: 5000,
    max_no_bytes: 10_000_000,
    max_no_files: 5,
    compress_on_rotate: true
  ]

config :owen_cloud,
  password: env!("PASSWORD", :string),
  eth0_port: env!("ETH0_PORT", :integer),
  eth0_slave: env!("ETH0_SLAVE", :integer),
  owcl_port: env!("OWCL_PORT", :integer),
  owcl_slave: env!("OWCL_SLAVE", :integer)
