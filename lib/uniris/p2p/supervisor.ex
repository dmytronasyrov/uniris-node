defmodule Uniris.P2P.Supervisor do
  @moduledoc false

  alias Uniris.Networking
  alias Uniris.P2P.BootstrappingSeeds
  alias Uniris.P2P.Endpoint
  alias Uniris.P2P.MemTable
  alias Uniris.P2P.MemTableLoader

  alias Uniris.Utils

  use Supervisor

  def start_link([seeds: _, seeds_file_path: _] = args) do
    Supervisor.start_link(__MODULE__, args, name: Uniris.P2PSupervisor)
  end

  def init(seeds: seeds, seeds_file_path: seeds_file_path) do
    nb_acceptors = Application.get_env(:uniris, Uniris.P2P)
    |> Keyword.fetch!(:nb_acceptors)

    transport = Application.get_env(:uniris, Uniris.P2P)
    |> Keyword.fetch!(:transport)

    {:ok, port} = Networking.get_p2p_port()

    endpoint_args = [
      nb_acceptors: nb_acceptors, 
      transport: transport, 
      port: port
    ]

    optional_children = [
      MemTable,
      MemTableLoader,
      {Endpoint, endpoint_args},
      {BootstrappingSeeds, [seeds: seeds, seeds_file_path: seeds_file_path]}
    ]

    children = Utils.configurable_children(optional_children)

    Supervisor.init(children, strategy: :one_for_one)
  end
end
