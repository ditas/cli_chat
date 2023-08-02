import Config

# Configures Elixir's Logger
config :logger, :console,
  level: :warning,
  format: "$time [$level] $message $metadata\n",
  metadata: [:file]

import_config "#{config_env()}.exs"
