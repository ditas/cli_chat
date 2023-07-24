defmodule CliChat.TestServer do
  use GenServer

  def start_link(_) do
    IO.puts("Start test server")
    GenServer.start_link(__MODULE__, [], [])
  end

  def init([]) do
    IO.puts("Init test server")
    {:ok, %{}}
  end
end
