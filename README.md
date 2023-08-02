# CliChat (Simple CLI Chat)

## Build && run

**Requires Elixir v1.14 and later**

```shell
MIX_ENV=prod mix escript.build
./cli_chat
```

## Use chat

```shell
help
```
shows available commands and arguments.

```shell
connect
```
connects to local server (defaults to localhost:4000).

```shell
connect <ip> <port>
```
connects to remote server with provided arguments.

```shell
set_name <name>
```
sets user name. Should be unique for a server instance.

When name is set you can start using chat.

## Architecture

CliChat is build without any additional dependencies. All deps defined in `mix.exs` are used for document generation and static analysis.
CliChat is build as CLI application. Build artifact as `cli_chat` file will be sufficient to start both client and server.
`main/1` function is defined in `application.ex` to work as starting point of the app. Then, usual supervision tree is started with the following components:
1. **Acceptor** - process to accept incoming connections via TCP.
2. **Server** - process to start and store all clients processes with respective names.
3. **Client** - simple loop to accept user input and hand it over to clients handler process (`server_handler.ex`).
