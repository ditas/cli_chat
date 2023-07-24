defmodule CliChat.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  # defined here to allow this app to start as CLI app
  def main(_args) do
    start(:normal, [])
  end

  @impl true
  def start(_type, _args) do
    port = Application.get_env(:cli_chat, :port, 4001)
    children = [
      # Starts a worker by calling: CliChat.Worker.start_link(arg)
      {CliChat.Server, [port]},
      # {CliChat.TestServer, [port]},
      {CliChat.Client, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CliChat.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
