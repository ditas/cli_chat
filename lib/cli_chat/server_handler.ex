defmodule CliChat.ServerHandler do
  @moduledoc """
  Process to maintain client connection.
  Receives incoming TCP data.
  Sends broadcasting info to Server.
  """
  require Logger
  use GenServer

  ## API

  @spec start_link(:inet.socket()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(client_sock) do
    Logger.debug("starting handler...")
    GenServer.start_link(__MODULE__, client_sock, [])
  end

  ## GenServer Callbacks

  @impl true
  def init(client_sock) do
    send(self(), :init)
    {:ok, %{client: client_sock}}
  end

  @impl true
  def handle_info({:broadcast, info}, %{client: socket} = state) do
    :gen_tcp.send(socket, "#{info}")
    {:noreply, state}
  end

  @impl true
  def handle_info(:init, %{client: _socket} = state) do
    GenServer.cast(:chat_server, {:info, "New client joined"})
    {:noreply, state}
  end

  @impl true
  def handle_info({:tcp, socket, data}, %{client: socket} = state) do
    :ok = handle_data(data, socket)
    {:noreply, state}
  end

  @impl true
  def handle_info({:tcp_closed, socket}, %{client: socket} = state) do
    IO.puts("Client closed the connection")
    {:stop, :normal, Map.put(state, :client, nil)}
  end

  ## Internal functions

  ## Checks if there's set_name command in incoming data.
  @spec handle_data(binary(), :inet.socket()) :: :ok | {:error, atom() | {:timeout, binary()}}
  defp handle_data(data, socket) do
    case String.split(data, ":") do
      ["set_name", name] -> handle_name(name, socket)
      [name | _rest] -> handle_message(name, data)
    end
  end

  ## Validates name.
  ## Notifies client with set_name result.
  @spec handle_name(binary(), :inet.socket()) :: :ok | {:error, atom() | {:timeout, binary()}}
  defp handle_name(name, socket) do
    case CliChat.Server.valid_name?(name, self()) do
      false -> :gen_tcp.send(socket, "set_name:false")
      true -> :gen_tcp.send(socket, "set_name:true")
    end
  end

  ## Sends messages to Server to broadcast them to all connected clients.
  @spec handle_message(binary(), binary()) :: :ok
  defp handle_message(user, data) do
    GenServer.cast(:chat_server, {:info, user, data})
  end
end
