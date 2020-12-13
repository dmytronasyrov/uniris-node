defmodule Uniris.P2P.BootstrappingSeeds do
  @moduledoc """
  Handle bootstrapping seeds lifecycle

  The networking seeds are firstly fetched either from file or environment variable (dev)

  The bootstrapping seeds support flushing updates
  """

  alias Uniris.Crypto

  alias Uniris.P2P.Node

  use GenServer

  @doc """
  Start the bootstrapping seeds holder

  Options:
  - File: path from the P2P bootstrapping seeds backup
  """
  # @spec start_link(opts :: [seeds_file :: String.t()]) :: {:ok, pid()}
  def start_link([seeds: _, seeds_file_path: _] = args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  List the current bootstrapping network seeds
  """
  @spec list() :: list(Node.t())
  def list, do: GenServer.call(__MODULE__, :list_seeds)

  @doc """
  Update the bootstrapping network seeds and flush them
  """
  @spec update(list(Node.t())) :: :ok
  def update(seeds), do: GenServer.call(__MODULE__, {:new_seeds, seeds})

  def init(seeds: seeds, seeds_file_path: seeds_file_path) do
    {:ok, %{seeds: seeds, seeds_file_path: seeds_file_path}}
  end

  def handle_call(:list_seeds, _from, state = %{seeds: seeds}) do
    {:reply, seeds, state}
  end

  def handle_call({:new_seeds, []}, _from, state), do: {:reply, :ok, state}

  def handle_call({:new_seeds, _seeds}, _from, state = %{seeds_file_path: ""}),
    do: {:reply, :ok, state}

  def handle_call({:new_seeds, seeds}, _from, state = %{seeds_file_path: seeds_file_path}) do
    first_node_public_key = Crypto.node_public_key(0)

    seeds
    |> Enum.reject(&(&1.first_public_key == first_node_public_key))
    |> nodes_to_seeds
    |> flush_seeds(seeds_file_path)

    {:reply, :ok, %{state | seeds: seeds}}
  end

  defp flush_seeds(_, ""), do: :ok

  defp flush_seeds(seeds_str, seeds_file_path) do
    File.write!(seeds_file_path, seeds_str, [:write])
  end

  @doc """
  Convert a list of nodes into a P2P seeds list

  ## Examples

      iex> [ %Node{ip: {127, 0, 0, 1}, port: 3000, first_public_key: "mykey"} ]
      ...> |> BootstrappingSeeds.nodes_to_seeds()
      "127.0.0.1:3000:6D796B6579"
  """
  @spec nodes_to_seeds(list(Node.t())) :: binary()
  def nodes_to_seeds(nodes) when is_list(nodes) do
    nodes
    |> Enum.reduce([], fn %Node{ip: ip, port: port, first_public_key: public_key}, acc ->
      acc ++ ["#{:inet_parse.ntoa(ip)}:#{port}:#{Base.encode16(public_key)}"]
    end)
    |> Enum.join("\n")
  end
end
