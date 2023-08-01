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
    GenServer.cast(:chat_server, {:info, "New client joined"})
    {:noreply, state}
  end

  @impl true
  def handle_info({:tcp, socket, data}, %{client: socket} = state) do
    handle_data(data, socket)

    # case data do
    #   "set_name:aaa" ->
    #     :timer.sleep(1000)
    #     :gen_tcp.send(socket, "set_name:true")
    #   _ ->
    #     GenServer.cast(:chat_server, {:info, data})
    # end

    {:noreply, state}
  end

  @impl true
  def handle_info({:tcp_closed, socket}, %{client: socket} = state) do
    IO.puts("SERVER: Client closed the connection.")
    {:stop, :normal, Map.put(state, :client, nil)}
  end

  ## Internal functions

  defp handle_data(data, socket) do
    case String.split(data, ":", [:global]) do
      ["set_name", name] -> handle_name(name, socket)
      _ -> handle_message(data)
    end
  end

  defp handle_name(name, socket) do
    case CliChat.Server.valid_name?(name, self()) do
      false -> :gen_tcp.send(socket, "set_name:false")
      true -> :gen_tcp.send(socket, "set_name:true")
    end
  end

  defp handle_message(message) do
    GenServer.cast(:chat_server, {:info, message})
  end

end
