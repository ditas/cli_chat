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
    default_host = Application.get_env(:cli_chat, :host, 'localhost')
    default_port = Application.get_env(:cli_chat, :port, 4000)
    children = [
      # Starts a worker by calling: CliChat.Worker.start_link(arg)
      {CliChat.Acceptor, []},
      {CliChat.Server, [default_host, default_port]},
      {CliChat.Client, [default_host, default_port]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CliChat.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
