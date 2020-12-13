defmodule Uniris.Networking.IPLookup.IPLookupImpl do
  @moduledoc false

  @callback get_node_ip() :: {:ok, :inet.ip_address()} | {:error, binary}
end
