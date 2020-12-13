defmodule Uniris.Networking.IPLookup.EnvImpl do
  @moduledoc false

  alias Uniris.Networking.IPLookup.IPLookupImpl

  @behaviour IPLookupImpl

  # Public

  @impl IPLookupImpl
  @spec get_node_ip() :: {:ok, :inet.ip_address()} | {:error, binary}
  def get_node_ip do
    Application.get_env(:uniris, Uniris.Networking)
    |> Keyword.fetch!(:load_from_system_env)
    |> case do
      true -> System.get_env("HOSTNAME")
      false -> 
        Application.get_env(:uniris, Uniris.Networking)
        |> Keyword.fetch!(:hostname)
    end
    |> String.to_charlist
    |> :inet.parse_address
  end
end
