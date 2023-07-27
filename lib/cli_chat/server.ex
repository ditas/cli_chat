defmodule CliChat.Server do
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

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: :chat_server)
  end

  def handle(client_socket) do
    GenServer.cast(:chat_server, {:handle, client_socket})
  end

  def valid_name?(name) do
    GenServer.call(:chat_server, {:check_name, name})
  end

  ## GenServer callbacks

  @impl true
  def init([]) do
    Process.flag(:trap_exit, true)
    IO.puts("SERVER: init")
    {:ok, %{clients: []}}
  end

  @impl true
  def handle_cast({:handle, socket}, %{clients: clients} = state) do
    {:ok, pid} = CliChat.ServerHandler.start_link(socket)
    :ok = :gen_tcp.controlling_process(socket, pid)
    {:noreply, Map.put(state, :clients, [pid|clients])}
  end

  @impl true
  def handle_cast({:info, info}, %{clients: clients} = state) do
    IO.puts("------server------CAST---------------")
    Enum.each(clients, fn(handler) ->
      send(handler, {:broadcast, info})
    end)
    {:noreply, state}
  end

  @impl true
  def handle_info({:EXIT, pid, reason}, %{clients: clients} = state) do
    IO.puts("------------HANDLER CRASHED----------#{inspect(pid)}")
    clients = List.delete(clients, pid)
    IO.puts("---------clients updated---------#{inspect(clients)}")
    {:noreply, Map.put(state, :clients, clients)}
  end

  @impl true
  def handle_info(any, state) do
    IO.puts("------------ANY----------#{inspect(any)}")
    {:noreply, state}
  end

end
