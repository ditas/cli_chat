defmodule CliChat.Acceptor do
  use GenServer

  ## API

  def start_link([]) do
    IO.puts("Start server")
    GenServer.start_link(__MODULE__, [], name: :chat_acceptor)
  end

  ## GenServer callbacks

  @impl true
  def init([]) do
    IO.puts("ACCEPTOR: init")
    {:ok, listen_socket} = :gen_tcp.listen(port, [:binary, {:active, true}])

    send(self(), :post_init)
    {:ok, %{listen_socket: listen_socket}}
  end

  @impl true
  def handle_info(:post_init, %{listen_socket: listen_socket} = state) do
    {:ok, client} = :gen_tcp.accept(listen_socket)
    IO.puts("ACCEPTOR: init 2 #{inspect(self())}")
    CliChat.Server.handle(client)
    :ok = :gen_tcp.controlling_process(client, :erlang.whereis(:chat_server))

    send(self(), :post_init)
    {:noreply, state}
  end

end
