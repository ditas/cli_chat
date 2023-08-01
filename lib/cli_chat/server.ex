defmodule CliChat.Server do
  require Logger
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

  def valid_name?(name, handler_pid) do
    case GenServer.call(:chat_server, {:check_name, name, handler_pid}) do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  ## GenServer callbacks

  @impl true
  def init([]) do
    Process.flag(:trap_exit, true)
    IO.puts("SERVER: init")
    {:ok, %{clients: []}}
  end

  @impl true
  def handle_call({:check_name, name, pid}, _from, %{clients: clients} = state) do
    case List.keymember?(clients, name, 0) do
      true -> {:reply, {:error, :name_exists}, state}
      false ->
        {res, state} = case List.keytake(clients, pid, 1) do
          {{:undefined, pid}, clients} ->
            {{:ok, :name_applied}, Map.put(state, :clients, [{name, pid}|clients])}
          {{old_name, pid}, clients} ->
            GenServer.cast(:chat_server, {:info, "Client " <> old_name <> " updates name to " <> name})
            {{:ok, :name_updated}, Map.put(state, :clients, [{name, pid}|clients])}
          nil ->
            Logger.warning("client with #{inspect(name)} and #{inspect(pid)} not found")
            {{:error, :client_not_found}, state}
        end
        {:reply, res, state}
    end
  end

  @impl true
  def handle_cast({:handle, socket}, %{clients: clients} = state) do
    {:ok, pid} = CliChat.ServerHandler.start_link(socket)
    :ok = :gen_tcp.controlling_process(socket, pid)
    {:noreply, Map.put(state, :clients, [{:undefined, pid}|clients])}
  end

  @impl true
  def handle_cast({:info, user, info}, %{clients: clients} = state) do
    IO.puts("------server------CAST---------------")
    Enum.each(clients, fn(
      {name, handler_pid}) when name != user ->
        send(handler_pid, {:broadcast, info})
      _ -> :ignore
    end)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:info, info}, %{clients: clients} = state) do
    IO.puts("------server------CAST---------------")
    Enum.each(clients, fn({_name, handler_pid}) ->
      send(handler_pid, {:broadcast, info})
    end)
    {:noreply, state}
  end

  @impl true
  def handle_info({:EXIT, pid, _reason}, %{clients: clients} = state) do
    IO.puts("------------HANDLER CRASHED----------#{inspect(pid)}")
    clients = List.keydelete(clients, pid, 1)
    IO.puts("---------clients updated---------#{inspect(clients)}")
    {:noreply, Map.put(state, :clients, clients)}
  end

  @impl true
  def handle_info(any, state) do
    IO.puts("------------ANY----------#{inspect(any)}")
    {:noreply, state}
  end

end
