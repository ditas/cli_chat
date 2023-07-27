defmodule CliChat.Acceptor do
  use GenServer

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :transient,
      shutdown: 500
    }
  end

  ## API

  def start_link([host, port]) do
    GenServer.start_link(__MODULE__, [host, port], name: :chat_acceptor)
  end

  def close() do
    IO.puts("Closing...")
    GenServer.cast(:chat_acceptor, :close)
  end

  ## GenServer callbacks

  @impl true
  def init([_host, port]) do
    IO.puts("ACCEPTOR: init")
    {:ok, listen_socket} = :gen_tcp.listen(port, [:binary, {:active, true}])

    send(self(), :post_init)
    {:ok, %{listen_socket: listen_socket}}
  end

  @impl true
  def handle_cast(:close, %{listen_socket: listen_socket} = state) do
    :ok = :gen_tcp.close(listen_socket)
    {:stop, :normal, state}
  end

  @impl true
  def handle_info(:post_init, %{listen_socket: listen_socket} = state) do
    {:ok, client_socket} = :gen_tcp.accept(listen_socket)
    IO.puts("ACCEPTOR: init 2 #{inspect(self())}")
    CliChat.Server.handle(client_socket)
    :ok = :gen_tcp.controlling_process(client_socket, :erlang.whereis(:chat_server))

    send(self(), :post_init)
    {:noreply, state}
  end

end
