defmodule UnirisValidation.DefaultImpl.BinarySequence do
  @moduledoc false

  alias UnirisNetwork.Node

  import Bitwise

  @doc """
  Create a binary sequence from a list of node and a subset by set the bit on the subset node

  ## Examples

     iex> UnirisValidation.DefaultImpl.BinarySequence.from_subset(
     ...> [%{last_public_key: "key1"}, %{last_public_key: "key2"}, %{last_public_key: "key3"}],
     ...> [%{last_public_key: "key1"}, %{last_public_key: "key3"}])
     <<1::1, 0::1, 1::1>>
  """
  @spec from_subset(node_list :: list(Node.t()), subset :: list(Node.t())) :: bitstring()
  def from_subset(node_list, subset) do
    nb_nodes = length(node_list)
    sequence = <<0::size(nb_nodes)>>
    do_from_subset(node_list, subset, sequence)
  end

  defp do_from_subset(list, [node | subset], sequence) do
    index = Enum.find_index(list, &(&1.last_public_key == node.last_public_key))
    <<prefix::size(index), _::size(1), rest::bitstring>> = sequence
    new_sequence = <<prefix::size(index), 1::size(1), rest::bitstring>>
    do_from_subset(list, subset, new_sequence)
  end

  defp do_from_subset(_, [], sequence), do: sequence

  @doc """
  Create a binary sequence from a list node and set bit regarding their availability

  ## Examples

    iex> UnirisValidation.DefaultImpl.BinarySequence.from_availability([
    ...> %{availability: 1}, %{availability: 0}, %{availability: 1}
    ...> ])
    <<1::1, 0::1, 1::1>>
  """
  @spec from_availability(list(Node.t())) :: bitstring()
  def from_availability(node_list) do
    nb_nodes = length(node_list)
    sequence = <<0::size(nb_nodes)>>
    do_from_availability(node_list, sequence, 0)
  end

  defp do_from_availability([node | list], sequence, index) do
    <<prefix::size(index), _::size(1), rest::bitstring>> = sequence
    new_sequence = <<prefix::size(index), node.availability::size(1), rest::bitstring>>
    do_from_availability(list, new_sequence, index + 1)
  end

  defp do_from_availability([], sequence, _), do: sequence

  @doc """
  Aggregate two bitstring using an OR bitwise operation

  ##  Examples

     iex> UnirisValidation.DefaultImpl.BinarySequence.aggregate(
     ...> <<1::1, 0::1, 1::1, 1::1>>,
     ...> <<0::1, 0::1, 1::1, 0::1>>
     ...>)
     <<1::1, 0::1, 1::1, 1::1>>
  """
  @spec aggregate(bitstring(), bitstring()) :: bitstring()
  def aggregate(seq1, seq2) do
    aggregate(seq1, seq2, 0)
  end

  defp aggregate(seq1, _, index) when bit_size(seq1) == index do
    seq1
  end

  defp aggregate(seq1, seq2, index) do
    <<prefix_seq1::size(index), bit_seq1::size(1), rest_seq1::bitstring>> = seq1
    <<_::size(index), bit_seq2::size(1), _::bitstring>> = seq2

    new_seq1 = <<prefix_seq1::size(index), bit_seq1 ||| bit_seq2::size(1), rest_seq1::bitstring>>

    aggregate(new_seq1, seq2, index + 1)
  end

  @doc """
  Represents a bitstring in a list of 0 and 1

  ## Examples

    iex> UnirisValidation.DefaultImpl.BinarySequence.extract(<<1::1, 0::1, 1::1>>)
    [1, 0, 1]

    iex> UnirisValidation.DefaultImpl.BinarySequence.extract(<<5::size(3)>>)
    [1, 0, 1]
  """
  @spec extract(bitstring()) :: list()
  def extract(sequence) do
    extract(sequence, [])
  end

  defp extract(<<b::size(1), bits::bitstring>>, acc) do
    extract(bits, [b | acc])
  end

  defp extract(<<>>, acc), do: acc |> Enum.reverse()
end