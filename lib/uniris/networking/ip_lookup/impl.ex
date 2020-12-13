defmodule Uniris.Networking.IPLookup.IPLookupImpl do
  @moduledoc false

  @callback get_ip() :: {:ok, :inet.ip_address()}
end
