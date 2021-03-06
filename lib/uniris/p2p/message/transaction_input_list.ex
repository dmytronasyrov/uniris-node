defmodule Uniris.P2P.Message.TransactionInputList do
  @moduledoc """
  Represents a message with a list of transaction inputs
  """
  defstruct inputs: [], calls: []

  alias Uniris.TransactionChain.TransactionInput

  @type t() :: %__MODULE__{
          inputs: list(TransactionInput.t()),
          calls: list(binary())
        }
end
