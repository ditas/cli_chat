defmodule CliChat.ServerHandler do
  use GenServer

  ## API

  def start_link(client_sock) do
    IO.puts("Start server handler")
    GenServer.start_link(__MODULE__, client_sock, [])
  end

  ## GenServer Callbacks

  @impl true
  def init(client_sock) do
    IO.puts("Init server handler")
    send(self(), :init)
    Process.send_after(self(), :ping, 5000)
    {:ok, %{client: client_sock}}
  end

  @impl true
  def handle_info({:broadcast, info}, %{client: socket} = state) do
    IO.puts("------handler------INFO---------------")
    :gen_tcp.send(socket, "SERVER BROADCAST: #{info} #{inspect(self())}")
    {:noreply, state}
  end

  @impl true
  def handle_info(:init, %{client: socket} = state) do
    :gen_tcp.send(socket, "SERVER INFO: you have joined #{inspect(self())}")
    GenServer.cast(:chat_server, {:info, "New client joined"})
    {:noreply, state}
  end

  @impl true
  def handle_info(:ping, %{client: socket} = state) do
    # :gen_tcp.send(socket, "Ping from the server! #{inspect(self())}")
    # Process.send_after(self(), :ping, 5000)
    exit(:error)
    {:noreply, state}
  end

  @impl true
  def handle_info({:tcp, socket, data}, %{client: socket} = state) do
    :gen_tcp.send(socket, "SERVER ECHO: #{data} #{inspect(self())}")
    {:noreply, state}
  end

  @impl true
  def handle_info({:tcp_closed, socket}, %{client: socket} = state) do
    IO.puts("SERVER: Client closed the connection.")
    {:stop, :normal, Map.put(state, :client, nil)}
  end
end
