defmodule CliChat.Server do
  use GenServer

  ## API
  def start_link([port]) do
    IO.puts("Start server")
    GenServer.start_link(__MODULE__, port, [])
  end


  ## GenServer callbacks
  @impl true
  def init(port) do
    IO.puts("SERVER: init")
    {:ok, listen_socket} = :gen_tcp.listen(port, [:binary, {:packet, 0}, {:active, true}, {:reuseaddr, true}])

    send(self(), :init)
    {:ok, %{listen_socket: listen_socket}}
  end

  @impl true
  def handle_info(:init, %{listen_socket: listen_socket} = state) do
    {:ok, socket} = :gen_tcp.accept(listen_socket)
    IO.puts("SERVER: init 2")
    {:noreply, Map.put(state, :socket, socket)}
  end

  @impl true
  def handle_info({:tcp, socket, data}, %{socket: socket} = state) do
    IO.puts("SERVER: received #{data}")
    :gen_tcp.send(socket, "Hello from the server!")
    {:noreply, state}
  end

  @impl true
  def handle_info({:tcp_closed, socket}, %{socket: socket}) do
    IO.puts("SERVER: Client closed the connection.")

    send(self(), :init)
    {:noreply, %{socket: nil}}
  end
end
