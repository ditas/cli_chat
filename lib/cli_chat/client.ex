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

  def start([default_host, default_port]) do
    IO.puts("Welcome to CLI Chat!")
    # loop(%{connected: false, config: {default_host, default_port}})
    {:ok, pid} = Task.start_link(fn -> run(default_host, default_port) end)
    loop(%{connected: false, config: {default_host, default_port}})
  end



  defp run(default_host, default_port) do
    {:ok, socket} = :gen_tcp.connect(default_host, default_port, [:binary, {:active, false}])

    receive_messages(socket)
    # send_user_input(socket)
  end

  defp receive_messages(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        IO.puts("Received: #{data}")
        receive_messages(socket)
      {:error, reason} ->
        IO.puts("Error receiving data: #{reason}")
    end
  end

  # defp send_user_input(socket) do
  #   IO.write("Enter your message: ")
  #   message = IO.gets("") |> String.trim()

  #   case :gen_tcp.send(socket, message) do
  #     :ok ->
  #       send_user_input(socket)
  #     {:error, reason} ->
  #       IO.puts("Error sending data: #{reason}")
  #   end
  # end



  defp loop(state) do
    IO.inspect(self())
    IO.puts("Enter a command: ")
    case IO.gets("") |> String.trim() do
      "exit" -> exit_chat(state)
      command -> handle_command(command, state)
    end
  end

  defp handle_command("help", state) do
    IO.puts("Available commands: help | exit | hello | connect | connect 'host' port")
    loop(state)
  end

  defp handle_command("hello", state) do
    IO.puts("Hello, world!")
    loop(state)
  end

  # defp handle_command("connect", %{connected: false, config: {default_host, default_port}}) do
  #   IO.puts("Connecting to server ...")
  #   {:ok, socket} = :gen_tcp.connect(default_host, default_port, [:binary, {:active, false}])
  #   loop(%{connected: true, socket: socket})
  # end

  # defp handle_command(_, %{connected: false} = state) do
  #   IO.puts("Connect to server first")
  #   loop(state)
  # end

  # defp handle_command(message, %{connected: true, socket: socket} = state) do
  #   IO.puts("You've sent: #{message}")
  #   :ok = :gen_tcp.send(socket, message)

  #   state = case :gen_tcp.recv(socket, 0) do
  #     {:ok, data} ->
  #       IO.puts("Received from server: #{data}")
  #       state

  #     {:error, reason} ->
  #       IO.puts("Error receiving data from server: #{reason}")
  #       :gen_tcp.close(socket)
  #       %{connected: false, socket: nil}
  #   end

  #   loop(state)
  # end

  defp handle_command(message, %{connected: true, socket: socket} = state) do
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

  defp exit_chat(%{connected: true, socket: socket}) do
    :gen_tcp.close(socket) ## TODO: close app
  end

end
