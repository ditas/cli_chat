defmodule CliChat.Server do
  use GenServer

  ## API

  def start_link([host, port]) do
    IO.puts("Start server")
    GenServer.start_link(__MODULE__, {host, port}, name: :chat_server)
  end

  def handle(client_socket) do
    GenServer.cast(:chat_server, {:handle, client_socket})
  end

  ## GenServer callbacks

  @impl true
  def init({_host, port}) do
    Process.flag(:trap_exit, true)
    IO.puts("SERVER: init")
    {:ok, listen_socket} = :gen_tcp.listen(port, [:binary, {:active, true}])

    send(self(), :post_init)
    {:ok, %{listen_socket: listen_socket, clients: []}}
  end

  # @impl true
  # def handle_cast({:handle, socket}, %{clients: clients} = state) do
  #   IO.puts("------server------CAST---------------")
  #   Enum.each(clients, fn(handler) ->
  #     send(handler, {:broadcast, info})
  #   end)
  #   {:noreply, state}
  # end

  @impl true
  def handle_cast({:info, info}, %{clients: clients} = state) do
    IO.puts("------server------CAST---------------")
    Enum.each(clients, fn(handler) ->
      send(handler, {:broadcast, info})
    end)
    {:noreply, state}
  end

  @impl true
  def handle_info(:post_init, %{listen_socket: listen_socket, clients: clients} = state) do
    {:ok, client} = :gen_tcp.accept(listen_socket)
    IO.puts("SERVER: init 2 #{inspect(self())}")
    {:ok, pid} = CliChat.ServerHandler.start_link(client)
    :ok = :gen_tcp.controlling_process(client, pid)

    # send(self(), :post_init)
    {:noreply, Map.put(state, :clients, [pid|clients])}
  end

  # @impl true
  # def handle_info({:EXIT, pid, reason}, %{clients: clients} = state) do
  #   IO.puts("------------HANDLER CRASHED----------#{inspect(pid)}")
  #   clients = List.delete(clients, pid)
  #   IO.puts("---------clients updated---------#{inspect(clients)}")
  #   {:noreply, Map.put(state, :clients, clients)}
  # end

  @impl true
  def handle_info(any, state) do
    IO.puts("------------ANY----------#{inspect(any)}")
    {:noreply, state}
  end

end
