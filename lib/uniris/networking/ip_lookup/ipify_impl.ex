defmodule Uniris.Networking.IPLookup.IPIFYImpl do
  @moduledoc false

  alias Uniris.Networking.IPLookup.IPLookupImpl

  @behaviour IPLookupImpl

  # TODO: move IP detection service into config
  @impl IPLookupImpl
  @spec get_ip() :: {:ok, :inet.ip_address()}
  def get_ip do
    with {:ok, {_, _, inet_addr}} <- :httpc.request('http://api.ipify.org') do
      :inets.stop()
      :inet.parse_address(inet_addr)
    else
      err -> throw "Unable to locate IP address: #{inspect err}"
    end
  end
end
