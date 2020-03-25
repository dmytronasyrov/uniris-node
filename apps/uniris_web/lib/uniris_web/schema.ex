defmodule UnirisWeb.Schema do
  @moduledoc false

  use Absinthe.Schema

  import_types __MODULE__.TransactionType

  query do
    field :transaction, :transaction do
      arg(:address, :hash)

      resolve(fn %{address: address}, _ ->
        case UnirisElection.storage_nodes(address)
        |> UnirisP2P.nearest_nodes()
        |> List.first()
        |> UnirisP2P.send_message({:get_transaction, address}) do
          {:ok, tx} ->
            {:ok, format_transaction(tx)}
          _ ->
            {:error, :transaction_not_exists}
        end
      end)
    end

    field :transactions, list_of(:transaction) do
      resolve(fn _, _ ->
        {:ok, UnirisChain.list_transactions() |> Enum.map(&format_transaction/1) }
      end)
    end
  end

  defp format_transaction(tx = %UnirisChain.Transaction{}) do
    %{
      address: tx.address,
      type: tx.type,
      timestamp: tx.timestamp,
      data: tx.data,
      previous_public_key: tx.previous_public_key,
      previous_signature: tx.previous_signature,
      origin_signature: tx.origin_signature,
      validation_stamp: %{
        proof_of_work: tx.validation_stamp.proof_of_work,
        proof_of_integrity: tx.validation_stamp.proof_of_integrity,
        ledger_movements: %{
          uco: %{
            previous: %{
              from: tx.validation_stamp.ledger_movements.uco.previous.from,
              amount: tx.validation_stamp.ledger_movements.uco.previous.amount
            },
            next: tx.validation_stamp.ledger_movements.uco.next
          }
        },
        node_movements: %{
          fee: tx.validation_stamp.node_movements.fee,
          rewards: Enum.map(tx.validation_stamp.node_movements.rewards, fn {key, amount} ->
            %{
              node: key,
              amount: amount
            }
          end)
        },
        signature: tx.validation_stamp.signature
      },
      cross_validation_stamps: Enum.map(tx.cross_validation_stamps, fn {sig, inconsistencies, public_key} ->
        %{
          node: public_key,
          signature: sig,
          inconsistencies: inconsistencies
        }
      end)
    }
  end
end