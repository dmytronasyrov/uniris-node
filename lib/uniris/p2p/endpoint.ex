defmodule Uniris.P2P.Endpoint do
  @moduledoc false

  use GenServer

  alias Uniris.P2P.Endpoint.ListenerSupervisor
  alias Uniris.P2P.Transport

  require Logger

  def start_link([nb_acceptors: _, transport: _, port: _] = args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init([nb_acceptors: nb_acceptors, transport: transport, port: port] = args) do
    {:ok, listen_socket} = Transport.listen(transport, port)

    Logger.info("P2P #{transport} Endpoint running on port #{port}")

    {:ok, listener_sup} =
      ListenerSupervisor.start_link(Keyword.merge(args, listen_socket: listen_socket))

    {:ok,
     %{
       listen_socket: listen_socket,
       port: port,
       listener_sup: listener_sup,
       nb_acceptors: nb_acceptors,
       transport: transport
     }}
  end

  @impl true
  def handle_info(
        {:DOWN, _ref, :process, pid, reason},
        state = %{
          acceptor_sup: listener_sup,
          listen_socket: listen_socket,
          nb_acceptors: nb_acceptors,
          transport: transport
        }
      )
      when pid == listener_sup do
    Logger.error("Listener supervisor failed! - #{inspect(reason)}")

    {:ok, listener_sup} =
      ListenerSupervisor.start_link(
        listen_socket: listen_socket,
        transport: transport,
        nb_acceptors: nb_acceptors
      )

    {:noreply, Map.put(state, :listener_sup, listener_sup)}
  end
end
