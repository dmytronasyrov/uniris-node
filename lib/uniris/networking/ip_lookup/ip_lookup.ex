defmodule Uniris.Networking.IPLookup do
  @moduledoc false

  alias __MODULE__.IPLookupImpl

  @behaviour IPLookupImpl

  # Public

  @impl IPLookupImpl
  @spec get_node_ip() :: {:ok, :inet.ip_address()} | {:error, binary}
  def get_node_ip, do: impl().get_node_ip()

  # Private
  
  defp impl do
    Application.get_env(:uniris, Uniris.Networking)
    |> Keyword.fetch!(:ip_lookup_provider)
  end
end
