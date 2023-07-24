defmodule CliChat.Client do

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start(_) do
    # Implement your application logic here
    IO.puts("Welcome to My CLI App!")
    loop(%{connected: false})
  end

  defp loop(state) do
    IO.puts("Enter a command: ")
    case IO.gets("") |> String.trim() do
      "exit" -> :ok
      command -> handle_command(command, state)
    end
  end

  defp handle_command("hello", state) do
    IO.puts("Hello, world!")
    loop(state)
  end

  defp handle_command("help", state) do
    IO.puts("Available commands: hello, exit, help, connect")
    loop(state)
  end

  defp handle_command("connect", %{connected: false}) do
    IO.puts("Connecting to server localhost:4000 ...")
    {:ok, socket} = :gen_tcp.connect('localhost', 4001, [:binary, {:packet, 0}, {:active, false}, {:reuseaddr, true}])
    loop(%{connected: true, socket: socket})
  end

  defp handle_command(_, %{connected: false} = state) do
    IO.puts("Connect to server first")
    loop(state)
  end

  defp handle_command(message, %{connected: true, socket: socket} = state) do\
    IO.puts("You've sent: #{message}")
    :ok = :gen_tcp.send(socket, message)

    state = case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        IO.puts("Received from server: #{data}")
        state

      {:error, reason} ->
        IO.puts("Error receiving data from server: #{reason}")
        :gen_tcp.close(socket)
        %{connected: false, socket: nil}
    end

    loop(state)
  end

end
