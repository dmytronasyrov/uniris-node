defmodule UnirisNetwork.NodeTest do
  use ExUnit.Case

  alias UnirisNetwork.Node
  alias  UnirisNetwork.P2P.Connection
  alias UnirisCrypto, as: Crypto

  import Mox

  setup :set_mox_global
  setup :verify_on_exit!

  setup do
    MockP2P
    |> stub(:start_link, fn _, _, _, pid ->
      send(pid, :connected)
      {:ok, self()}
    end)
    |> stub(:send_message, fn _, {from, _msg} ->
      send(from, {:p2p_response, {:ok, "hello", "public_key"}})
      :ok
    end)

    :ok
  end

  test "start_link/1 should create a new node and register it with its public keys" do
    pub = Crypto.generate_random_keypair()
    pub2 = Crypto.generate_random_keypair()

    {:ok, pid} =
      Node.start_link(first_public_key: pub, last_public_key: pub2, ip: {127, 0, 0, 1}, port: 3000)

    Process.sleep(200)

    assert Process.alive?(pid)
    assert match?([{_, _}], Registry.lookup(UnirisNetwork.NodeRegistry, pub))
    assert match?([{_, _}], Registry.lookup(UnirisNetwork.NodeRegistry, pub2))
  end

  test "available/1 should state the node as available" do
    pub = Crypto.generate_random_keypair()

    {:ok, pid} =
      Node.start_link(first_public_key: pub, last_public_key: pub, ip: {127, 0, 0, 1}, port: 3000)

    Node.available(pub)
    assert match?(%{availability: 1}, :sys.get_state(pid))
  end

  test "unavailable/1 should state the node as unavailable" do
    pub = Crypto.generate_random_keypair()

    {:ok, pid} =
      Node.start_link(first_public_key: pub, last_public_key: pub, ip: {127, 0, 0, 1}, port: 3000)

    Node.available(pub)
    Node.unavailable(pub)
    assert match?(%{availability: 0}, :sys.get_state(pid))
  end

  test "details/1 should retrieve the node information" do
    pub = Crypto.generate_random_keypair()
    pub2 = Crypto.generate_random_keypair()

    {:ok, _pid} =
      Node.start_link(first_public_key: pub, last_public_key: pub2, ip: {127, 0, 0, 1}, port: 3000)

    assert match?(%Node{}, Node.details(pub))
    assert match?(%Node{}, Node.details(pub2))
  end

  test "update_basics/4 should update the basic node information" do
    pub = Crypto.generate_random_keypair()

    {:ok, _pid} =
      Node.start_link(first_public_key: pub, last_public_key: pub, ip: {127, 0, 0, 1}, port: 3000)

    pub2 = Crypto.generate_random_keypair()
    Node.update_basics(pub, pub2, "88.100.242.12", 3000)
    node = Node.details(pub)
    assert node.last_public_key == pub2
    assert node.ip == "88.100.242.12"
  end

  test "update_network_patch/2 should update the network patch" do
    pub = Crypto.generate_random_keypair()

    {:ok, _pid} =
      Node.start_link(first_public_key: pub, last_public_key: pub, ip: {127, 0, 0, 1}, port: 3000)

    Node.update_network_patch(pub, "AA0")
    %{network_patch: network_patch} = Node.details(pub)
    assert network_patch == "AA0"
  end

  test "update_average_availability/2 should update the average availability" do
    pub = Crypto.generate_random_keypair()

    {:ok, _pid} =
      Node.start_link(first_public_key: pub, last_public_key: pub, ip: {127, 0, 0, 1}, port: 3000)

    Node.update_average_availability(pub, 0.5)
    %{average_availability: average_availability} = Node.details(pub)
    assert average_availability == 0.5
  end

  test "send_message/2 should call the send message through connection" do
    pub = Crypto.generate_random_keypair()

    {:ok, _} =
      Node.start_link(first_public_key: pub, last_public_key: pub, ip: {127, 0, 0, 1}, port: 3000)

    {:ok, pid} = Connection.start_link(public_key: pub, ip: {127, 0, 0, 1}, port: 3000)

    assert {:ok, "hello"} = Node.send_message(pub, {pid, "hello"})

  end
end