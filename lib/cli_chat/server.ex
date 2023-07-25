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
    {:ok, %{listen_socket: listen_socket, clients: []}}
  end

  @impl true
  def handle_info(:init, %{listen_socket: listen_socket, clients: clients} = state) do
    {:ok, client} = :gen_tcp.accept(listen_socket)
    IO.puts("SERVER: init 2 #{inspect(self())}")
    {:ok, pid} = CliChat.ServerHandler.start_link(client)
    :ok = :gen_tcp.controlling_process(client, pid)

    send(self(), :init)
    {:noreply, Map.put(state, :clients, [pid|clients])}
  end

end
