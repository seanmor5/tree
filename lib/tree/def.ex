defprotocol Tree.Def do
  @moduledoc """
  Protocol for traversing and reducing arbitrarily nested
  data structures with a tree-like structure.
  """

  @doc """
  Traverse receives a data structure with `acc` and `fun`.
  
  The function receives a leaf value and the accumulator for each
  leaf in the container. It returns a two element tuple
  with the updated container and the accumulator.
  """
  @spec traverse(t(), acc, (term(), acc -> {term(), acc})) :: acc when acc: term()
  def traverse(data, acc, fun)

  @doc """
  Reduces a data structure with `acc` and `fun`.
  
  The function receives a leaf value and the accumulator for each
  leaf in the container. It returns the updated accumulator.
  """
  @spec reduce(t(), acc, (term(), acc -> acc)) :: acc when acc: term()
  def reduce(data, acc, fun)
end

defimpl Tree.Def, for: List do
  def traverse(list, acc, fun) do
    Enum.map_reduce(list, acc, fun)
  end

  def reduce(list, acc, fun) do
    Enum.reduce(list, acc, fun)
  end
end

defimpl Tree.Def, for: Tuple do
  def traverse(tuple, acc, fun) do
    tuple
    |> Tuple.to_list()
    |> Enum.map_reduce(acc, fun)
    |> then(fn {list, acc} -> {List.to_tuple(list), acc} end)
  end

  def reduce(tuple, acc, fun) do
    tuple
    |> Tuple.to_list()
    |> Enum.reduce(acc, fun)
  end
end

defimpl Tree.Def, for: Map do
  def traverse(map, acc, fun) do
    map
    |> Map.to_list()
    |> Enum.sort()
    |> Enum.map_reduce(acc, fn {k, v}, acc ->
      {v, acc} = fun.(v, acc)
      {{k, v}, acc}
    end)
    |> then(fn {list, acc} -> {Map.new(list), acc} end)
  end

  def reduce(map, acc, fun) do
    map
    |> Map.to_list()
    |> Enum.sort()
    |> Enum.reduce(acc, fn {_, v}, acc -> fun.(v, acc) end)
  end
end
