defmodule Uniris.Networking do
  @moduledoc false

  alias __MODULE__.IPLookup
  
  # Public
  
  @spec get_node_ip() :: {:ok, :inet.ip_address()} | {:error, binary}
  defdelegate get_node_ip, to: IPLookup

  @spec get_p2p_port() :: {:ok, integer} | {:error, binary}
  def get_p2p_port do
    Application.get_env(:uniris, Uniris.Networking)
    |> Keyword.fetch!(:load_from_system_env)
    |> case do
      true -> 
        {port, ""} = System.get_env("UNIRIS_P2P_PORT")
        |> Integer.parse
        
        {:ok, port}
      false -> 
        Application.get_env(:uniris, Uniris.Networking)
        |> Keyword.fetch(:port)
    end
  end
end