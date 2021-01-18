defmodule Uniris.Application do
  @moduledoc false

  use Application
  
  require Logger

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
    children = [
      {Registry, keys: :duplicate, name: Uniris.PubSubRegistry},
      DBSupervisor,
      TransactionChainSupervisor,
      CryptoSupervisor,
      ElectionSupervisor,
      P2PSupervisor,
      MiningSupervisor,
      ContractsSupervisor,
      BeaconChainSupervisor,
      SharedSecretsSupervisor,
      AccountSupervisor,
      GovernanceSupervisor,
      SelfRepairSupervisor,
      WebSupervisor,
      Bootstrap,
      {Task.Supervisor, name: Uniris.TaskSupervisor}
    ]

    opts = [strategy: :rest_for_one, name: Uniris.Supervisor]
    res = Supervisor.start_link(Utils.configurable_children(children), opts)

    Logger.debug "DEBUG: STARTING UNIRIS SYSTEM"
    Logger.info "INFO: STARTING UNIRIS SYSTEM"
    Logger.warn "WARN: STARTING UNIRIS SYSTEM"
    Logger.error "ERROR: STARTING UNIRIS SYSTEM"

    res
  end

  def config_change(changed, _new, removed) do
    # Tell Phoenix to update the endpoint configuration
    # whenever the application is updated.
    WebEndpoint.config_change(changed, removed)
    :ok
  end
end
