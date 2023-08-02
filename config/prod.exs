import Config

config :cli_chat,
  host: "localhost",
  port: 4000

# Do not print debug messages in production
config :logger, level: :info
