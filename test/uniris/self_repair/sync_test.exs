defmodule Uniris.SelfRepair.SyncTest do
  use UnirisCase, async: false

  alias Uniris.BeaconChain
  alias Uniris.BeaconChain.Slot, as: BeaconSlot
  alias Uniris.BeaconChain.Slot.TransactionInfo
  alias Uniris.BeaconChain.SlotTimer, as: BeaconSlotTimer
  alias Uniris.BeaconChain.Subset, as: BeaconSubset

  alias Uniris.Crypto

  alias Uniris.P2P
  alias Uniris.P2P.Message.BeaconSlotList
  alias Uniris.P2P.Message.GetBeaconSlots
  alias Uniris.P2P.Message.GetTransaction
  alias Uniris.P2P.Message.GetTransactionChain
  alias Uniris.P2P.Message.GetTransactionInputs
  alias Uniris.P2P.Message.TransactionInputList
  alias Uniris.P2P.Message.TransactionList
  alias Uniris.P2P.Node

  alias Uniris.TransactionFactory

  alias Uniris.TransactionChain.TransactionInput

  alias Uniris.SelfRepair.Sync

  alias Uniris.Utils

  import Mox

  describe "last_sync_date/0" do
    test "should get the network startup date if not last sync file" do
      assert Sync.last_sync_date() |> Utils.truncate_datetime() ==
               Application.get_env(:uniris, Sync)[:network_startup_date]
               |> Utils.truncate_datetime()
    end

    test "should get the last sync date from the stored filed file" do
      file = Application.get_env(:uniris, Sync) |> Keyword.fetch!(:last_sync_file)

      last_sync_date = DateTime.utc_now() |> DateTime.add(-60) |> Utils.truncate_datetime()

      new_sync_date = last_sync_date |> DateTime.to_unix() |> Integer.to_string()
      :ok = File.write!(file, new_sync_date, [:write])

      assert Sync.last_sync_date() == last_sync_date
    end
  end

  test "store_last_sync_date/1 should store the last sync date into the last sync file" do
    last_sync_date = DateTime.utc_now() |> DateTime.add(-60) |> Utils.truncate_datetime()
    :ok = Sync.store_last_sync_date(last_sync_date)
    assert Sync.last_sync_date() == last_sync_date
  end

  describe "load_missed_transactions/2" do
    setup do
      start_supervised!({BeaconSlotTimer, interval: "* * * * * *", trigger_offset: 0})
      Enum.each(BeaconChain.list_subsets(), &BeaconSubset.start_link(subset: &1))

      welcome_node = %Node{
        first_public_key: "key1",
        last_public_key: "key1",
        available?: true,
        geo_patch: "BBB",
        network_patch: "BBB"
      }

      coordinator_node = %Node{
        first_public_key: Crypto.node_public_key(0),
        last_public_key: Crypto.node_public_key(),
        authorized?: true,
        available?: true,
        authorization_date: DateTime.utc_now() |> DateTime.add(-10),
        geo_patch: "AAA",
        network_patch: "AAA"
      }

      storage_nodes = [
        %Node{
          ip: {127, 0, 0, 1},
          port: 3000,
          first_public_key: "key3",
          last_public_key: "key3",
          available?: true,
          geo_patch: "BBB",
          network_patch: "BBB"
        }
      ]

      Enum.each(storage_nodes, &P2P.add_node(&1))

      P2P.add_node(welcome_node)
      P2P.add_node(coordinator_node)

      {:ok,
       %{
         welcome_node: welcome_node,
         coordinator_node: coordinator_node,
         storage_nodes: storage_nodes
       }}
    end

    test "should retrieve the missing beacon slots from the given date", context do
      inputs = [%TransactionInput{from: "@Alice2", amount: 10.0, spent?: true, type: :UCO}]
      tx = TransactionFactory.create_valid_transaction(context, inputs)

      missing_slots = [
        %BeaconSlot{
          transactions: [
            %TransactionInfo{
              address: tx.address,
              type: :transfer,
              timestamp: DateTime.utc_now()
            }
          ]
        }
      ]

      me = self()

      MockDB
      |> stub(:write_transaction_chain, fn _ ->
        send(me, :storage)
        :ok
      end)

      MockTransport
      |> stub(:send_message, fn
        _, _, %GetBeaconSlots{} ->
          {:ok, %BeaconSlotList{slots: missing_slots}}

        _, _, %GetTransaction{} ->
          {:ok, tx}

        _, _, %GetTransactionInputs{} ->
          {:ok, %TransactionInputList{inputs: inputs}}

        _, _, %GetTransactionChain{} ->
          {:ok, %TransactionList{transactions: []}}
      end)

      assert :ok = Sync.load_missed_transactions(DateTime.utc_now() |> DateTime.add(-1), "AAA")

      assert_receive :storage
    end
  end
end
