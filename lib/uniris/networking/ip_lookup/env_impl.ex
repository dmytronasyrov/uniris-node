defmodule Uniris.Networking.IPLookup.EnvImpl do
  @moduledoc false

  alias Uniris.Networking.IPLookup.IPLookupImpl

  @behaviour IPLookupImpl

  # Public

  @impl IPLookupImpl
  @spec get_node_ip() :: {:ok, :inet.ip_address()} | {:error, binary}
  def get_node_ip do
    with host <- System.get_env("HOSTNAME"),
    chars <- String.to_charlist(host),
    {:ok, ip} <- :inet.parse_address(chars) do
      {:ok, ip}
    else
      reason -> {:error, reason}
    end
  end
end
