defmodule CliChat.Server do
  @moduledoc """
  Process to maintain connected clients names and their relative processes (server_handler.ex)
  Obtains socket from Acceptor process.
  Starts process to handle one socket per client.
  Collects and validates clients names.
  Receives broadcasting info from client processes. Broadcasts it to all connected clients.
  """
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

  @spec start_link(list()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: :chat_server)
  end

  @doc """
  Obtains socket from Acceptor.
  Starts new controlling process for socket.
  Stores processes pids and client names in state.
  """
  @spec handle(:inet.socket()) :: :ok
  def handle(client_socket) do
    GenServer.cast(:chat_server, {:handle, client_socket})
  end

  @doc """
  Checks if name exists in state.
  """
  @spec valid_name?(binary(), pid()) :: boolean()
  def valid_name?(name, handler_pid) do
    case GenServer.call(:chat_server, {:check_name, name, handler_pid}) do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  ## GenServer callbacks

  @impl true
  def init([]) do
    Logger.debug("starting server...")
    Process.flag(:trap_exit, true)
    {:ok, %{clients: []}}
  end

  @impl true
  def handle_call({:check_name, name, pid}, _from, %{clients: clients} = state) do
    case List.keymember?(clients, name, 0) do
      true ->
        {:reply, {:error, :name_exists}, state}

      false ->
        {res, state} =
          case List.keytake(clients, pid, 1) do
            {{:undefined, pid}, clients} ->
              {{:ok, :name_applied}, Map.put(state, :clients, [{name, pid} | clients])}

            {{old_name, pid}, clients} ->
              GenServer.cast(
                :chat_server,
                {:info, "Client " <> old_name <> " updates name to " <> name}
              )

              {{:ok, :name_updated}, Map.put(state, :clients, [{name, pid} | clients])}

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
    {:noreply, Map.put(state, :clients, [{:undefined, pid} | clients])}
  end

  @impl true
  def handle_cast({:info, user, info}, %{clients: clients} = state) do
    Enum.each(clients, fn
      {name, handler_pid} when name != user ->
        send(handler_pid, {:broadcast, info})

      _ ->
        :ignore
    end)

    {:noreply, state}
  end

  @impl true
  def handle_cast({:info, info}, %{clients: clients} = state) do
    Enum.each(clients, fn {_name, handler_pid} ->
      send(handler_pid, {:broadcast, info})
    end)

    {:noreply, state}
  end

  @impl true
  def handle_info({:EXIT, pid, reason}, %{clients: clients} = state) do
    Logger.warning("handler #{inspect(pid)} exited with #{inspect(reason)}")
    clients = List.keydelete(clients, pid, 1)
    {:noreply, Map.put(state, :clients, clients)}
  end

  @impl true
  def handle_info(any, state) do
    Logger.warning("unknown message: #{inspect(any)}")
    {:noreply, state}
  end
end
