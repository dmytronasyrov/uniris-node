defmodule Uniris.Application do
  @moduledoc false

  use Application

  alias Uniris.Networking
  alias Uniris.P2P
  alias Uniris.SelfRepair

  alias Uniris.Account.Supervisor, as: AccountSupervisor
  alias Uniris.BeaconChain.Supervisor, as: BeaconChainSupervisor
  alias Uniris.Bootstrap
  alias Uniris.Contracts.Supervisor, as: ContractsSupervisor
  alias Uniris.Crypto.Supervisor, as: CryptoSupervisor
  alias Uniris.DB.Supervisor, as: DBSupervisor
  alias Uniris.Election.Supervisor, as: ElectionSupervisor
  alias Uniris.Governance.Supervisor, as: GovernanceSupervisor
  alias Uniris.Mining.Supervisor, as: MiningSupervisor
  alias Uniris.P2P.Supervisor, as: P2PSupervisor
  alias Uniris.SelfRepair.Supervisor, as: SelfRepairSupervisor
  alias Uniris.SharedSecrets.Supervisor, as: SharedSecretsSupervisor
  alias Uniris.TransactionChain.Supervisor, as: TransactionChainSupervisor

  alias Uniris.Utils

  alias UnirisWeb.Endpoint, as: WebEndpoint
  alias UnirisWeb.Supervisor, as: WebSupervisor

  def start(_type, _args) do
    p2p_args = build_p2p_args()

    bootstrap_args = p2p_args[:seeds]
    |> build_bootstrap_args
    
    children = [
      {Registry, keys: :duplicate, name: Uniris.PubSubRegistry},
      DBSupervisor,
      TransactionChainSupervisor,
      CryptoSupervisor,
      ElectionSupervisor,
      {P2PSupervisor, p2p_args},
      MiningSupervisor,
      ContractsSupervisor,
      BeaconChainSupervisor,
      SharedSecretsSupervisor,
      AccountSupervisor,
      GovernanceSupervisor,
      SelfRepairSupervisor,
      WebSupervisor,
      {Bootstrap, bootstrap_args},
      {Task.Supervisor, name: Uniris.TaskSupervisor}
    ]

    opts = [strategy: :rest_for_one, name: Uniris.Supervisor]
    Supervisor.start_link(Utils.configurable_children(children), opts)
  end

  def config_change(changed, _new, removed) do
    # Tell Phoenix to update the endpoint configuration
    # whenever the application is updated.
    WebEndpoint.config_change(changed, removed)
    :ok
  end

  # Private

  defp build_p2p_args do
    seeds_env = Application.get_env(:uniris, Uniris.P2P)
    |> Keyword.fetch!(:load_from_system_env)
    |> case do
      true -> System.get_env("UNIRIS_P2P_SEEDS") || []
      false -> []
    end

    {seeds_file, seeds_file_path} = Application.get_env(:uniris, Uniris.P2P)
    |> Keyword.fetch(:seeds_file)
    |> case do
      {:ok, file} -> 
        extracted_seeds = Application.app_dir(:uniris, file)
        |> File.read!()
        |> extract_seeds

        {extracted_seeds || [], file}
      :error -> {[], nil}
    end

    [
      seeds: Enum.concat(seeds_env, seeds_file),
      seeds_file_path: seeds_file_path
    ]
  end

  defp extract_seeds(seeds_str) do
    seeds_str
    |> String.split("\n", trim: true)
    |> Enum.map(fn seed ->
      [ip, port, public_key] = String.split(seed, ":")
      {:ok, ip} = ip 
      |> String.to_charlist() 
      |> :inet.parse_address()
      
      %Uniris.P2P.Node{
        ip: ip,
        port: String.to_integer(port),
        last_public_key: Base.decode16!(public_key, case: :mixed),
        first_public_key: Base.decode16!(public_key, case: :mixed)
      }
    end)
  end

  defp build_bootstrap_args(bootstrapping_seeds) do
    {:ok, ip} = Networking.get_node_ip()
    {:ok, port} = Networking.get_p2p_port()
    last_sync_date = SelfRepair.last_sync_date()

    [
      ip: ip, 
      port: port, 
      bootstrapping_seeds: bootstrapping_seeds, 
      last_sync_date: last_sync_date
    ]
  end
end
