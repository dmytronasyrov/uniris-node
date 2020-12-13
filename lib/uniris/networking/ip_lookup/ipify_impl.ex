defmodule Uniris.Networking.IPLookup.IPIFYImpl do
  @moduledoc false

  alias Uniris.Networking.IPLookup.IPLookupImpl

  @behaviour IPLookupImpl

  # TODO: move IP detection service into config
  @impl IPLookupImpl
  @spec get_node_ip() :: {:ok, :inet.ip_address()} | {:error, binary}
  def get_node_ip do
    with {:ok, {_, _, inet_addr}} <- :httpc.request('http://api.ipify.org'),
    {:ok, ip} <- :inet.parse_address(inet_addr) do
      :inets.stop()

      {:ok, ip}
    else
      reason -> {:error, reason}
    end
  end
end
