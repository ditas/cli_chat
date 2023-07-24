defmodule CliChatTest do
  use ExUnit.Case
  doctest CliChat

  test "greets the world" do
    assert CliChat.hello() == :world
  end
end
