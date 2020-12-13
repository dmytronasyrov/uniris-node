defmodule Uniris.Networking.IPLookup.EnvImpl do
  @moduledoc false

  alias Uniris.Networking.IPLookup.IPLookupImpl

  @behaviour IPLookupImpl

  # Public

  @impl IPLookupImpl
  @spec get_ip() :: {:ok, :inet.ip_address()}
  def get_ip do
    with host <- System.get_env("HOSTNAME"),
    chars <- String.to_charlist(host),
    {:ok, ip} <- :inet.parse_address(chars) do
      {:ok, ip}
    else
      err -> raise "expected the HOSTNAME env variable to be set as IP address: #{inspect err}"
    end
  end
end
