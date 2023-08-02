defmodule CliChat.Client do
  @moduledoc """
    Handles user input and prints server replies to the CLI
  """
  require Logger

  @dialyzer {:nowarn_function,
             [
               start: 1,
               loop: 1,
               read_input: 1,
               exit_chat: 1,
               handle_command: 2,
               handle_command: 3,
               connect: 3,
               cast_to_charlist: 1,
               cast_to_integer: 1
             ]}

  @commands ["help", "connect", "set_name", "exit"]

  @doc """
  Returns a specification to start this module under a supervisor.
  """
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start, [opts]},
      type: :worker,
      restart: :transient,
      shutdown: 500
    }
  end

  @doc """
  Starts loop to handle user input
  """
  def start([default_host, default_port]) do
    Logger.debug("starting client...")
    loop(%{connected: false, config: {default_host, default_port}, name: nil})
  end

  @doc """
  Function runs as spawned process to receive TCP packets from server and sends some replies to the client process (shell) or prints it out
  """
  def recv(socket, client_pid) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, "set_name:true"} ->
        IO.puts("Name is valid")
        send(client_pid, {:set_name, true})
        recv(socket, client_pid)

      {:ok, "set_name:false"} ->
        IO.puts("Name is invalid")
        send(client_pid, {:set_name, false})
        recv(socket, client_pid)

      {:ok, data} ->
        IO.puts("-> #{data}")
        recv(socket, client_pid)

      {:error, reason} ->
        IO.puts("Error receiving data from server: #{reason}")
        :gen_tcp.close(socket)
    end
  end

  ## Internal functions

  ## Loops to read user input. Prints out suggestions
  defp loop(%{connected: true, socket: _socket, name: nil} = state) do
    IO.puts("Set your name with command 'set_name': ")
    read_input(state)
  end

  defp loop(%{connected: true, socket: _socket, name: name} = state) do
    IO.puts(name <> ": ")
    read_input(state)
  end

  defp loop(state) do
    IO.puts("Enter a command: ")
    read_input(state)
  end

  ## Reads user input. Exits on 'exit' command
  defp read_input(state) do
    case IO.gets("") |> String.trim() do
      "exit" -> exit_chat(state)
      command -> handle_command(command, state)
    end
  end

  ## Handles user input. Splits it to command and data. Executes commands
  ## Available commands are: "help", "connect", "set_name", "exit"
  defp handle_command(message, state) do
    [command | rest] = String.split(message, " ", [:global])

    case Enum.member?(@commands, command) do
      true -> handle_command(command, rest, state)
      false -> handle_command(message, nil, state)
    end
  end

  defp handle_command("help", _, state) do
    IO.puts("Available commands: help | connect | connect host port | set_name some_name | exit")
    loop(state)
  end

  defp handle_command("connect", [host, port], %{connected: false} = state) do
    IO.puts("Connecting to remote server...")
    state = connect(host, port, state)
    loop(state)
  end

  defp handle_command(
         "connect",
         _,
         %{connected: false, config: {default_host, default_port}} = state
       ) do
    IO.puts("Connecting to local server...")
    state = connect(default_host, default_port, state)
    loop(state)
  end

  defp handle_command(_, _, %{connected: false} = state) do
    IO.puts("Connect to server first")
    loop(state)
  end

  defp handle_command("set_name", [name], %{connected: true, socket: socket, name: _} = state) do
    IO.puts("Checking name: #{name}...")
    :ok = :gen_tcp.send(socket, "set_name:" <> name)

    receive do
      {:set_name, true} ->
        IO.puts("CLIENT Name is valid")
        loop(Map.put(state, :name, name))

      {:set_name, false} ->
        IO.puts("CLIENT Name is invalid")
        loop(state)
    after
      5_000 -> loop(state)
    end
  end

  defp handle_command(_, _, %{connected: true, socket: _socket, name: nil} = state) do
    IO.puts("Set name first")
    loop(state)
  end

  defp handle_command(message, _, %{connected: true, socket: socket, name: name} = state) do
    :ok = :gen_tcp.send(socket, name <> ": " <> message)
    loop(state)
  end

  ## Execution of 'connect' command. Connects to provided host:port via TCP. Spawns process to receive incoming data from TCP
  defp connect(host, port, state) do
    {:ok, socket} =
      :gen_tcp.connect(cast_to_charlist(host), cast_to_integer(port), [:binary, {:active, false}])

    shell_pid = self()
    spawn(__MODULE__, :recv, [socket, shell_pid])

    state
    |> Map.put(:connected, true)
    |> Map.put(:socket, socket)
  end

  ## Closes open sockets
  defp exit_chat(%{connected: true, socket: socket}) do
    CliChat.Acceptor.close()
    :ok = :gen_tcp.close(socket)
  end

  defp cast_to_charlist(value) when is_bitstring(value) do
    String.to_charlist(value)
  end

  defp cast_to_charlist(value) do
    value
  end

  defp cast_to_integer(value) when is_number(value) do
    value
  end

  defp cast_to_integer(value) when is_binary(value) or is_bitstring(value) do
    String.to_integer(value)
  end
end
