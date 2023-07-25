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
    {:ok, %{client: client_sock}}
  end

  @impl true
  def handle_info({:tcp, socket, data}, %{client: socket} = state) do
    IO.puts("SERVER: received #{data}")
    :gen_tcp.send(socket, "Hello from the server! #{inspect(self())}")
    {:noreply, state}
  end

  @impl true
  def handle_info({:tcp_closed, socket}, %{socket: socket} = state) do
    IO.puts("SERVER: Client closed the connection.")

    send(self(), :init)
    {:noreply, Map.put(state, :client, nil)}
  end
end
