defmodule Tree do
  @moduledoc """
  Functions for manipulating nested tree-like data structures.
  """

  @doc """
  Returns true if all leaves in the data structure
  are truthy.

  ## Examples

      iex> Tree.all?([1, 2, 3])
      true

      iex> Tree.all?([{1, 2}, %{a: false}])
      false
  """
  def all?(tree) do
    tree
    |> leaves()
    |> Enum.all?()
  end

  @doc """
  Returns true if fun.(leaf) is truthy for all leaves in
  tree.

  ## Examples

      iex> Tree.all?([1, 2, 3], fn x -> rem(x, 2) == 0 end)
      false

      iex> Tree.all?([{2, 4}, %{a: 6}], fn x -> rem(x, 2) == 0 end)
      true
  """
  def all?(tree, fun) do
    tree
    |> leaves()
    |> Enum.all?(fun)
  end

  @doc """
  Returns true if any leaves in the data structure
  are truty.

  ## Examples

      iex> Tree.any?([1, 2, 3])
      true

      iex> Tree.any?({[false, {false}]})
      false
  """
  def any?(tree) do
    tree
    |> leaves()
    |> Enum.any?()
  end

  @doc """
  Returns true if fun.(leaf) is truthy for all leaves in
  tree.

  ## Examples

      iex> Tree.any?([1, 2, 3], fn x -> rem(x, 2) == 0 end)
      true

      iex> Tree.any?([{2, 4}, %{a: 6}], fn x -> rem(x, 2) == 0 end)
      true
  """
  def any?(tree, fun) do
    tree
    |> leaves()
    |> Enum.any?(fun)
  end

  @doc """
  Invokes the given `fun` for each leaf in the data structure.

  Returns `:ok`.
  """
  def each(tree, fun) do
    map(tree, fun)
    :ok
  end

  @doc """
  Returns `true` if there are no leaves in the data structure.

  ## Examples

      iex> Tree.empty?([{%{}, []}])
      true

      iex> Tree.empty?([{%{}, [1]}])
      false
  """
  def empty?(tree) do
    tree
    |> leaves()
    |> Enum.empty?()
  end

  @doc """
  Applies the given function to each leaf in the data structure
  and returns a flat list of transformed leaves.

  ## Examples

      iex> Tree.flat_map([1, 2, 3], fn x -> x + 1 end)
      [2, 3, 4]

      iex> Tree.flat_map([{1, 2}, %{a: 3}], fn x -> x + 1 end)
      [2, 3, 4]
  """
  def flat_map(tree, fun) do
    tree
    |> recur_flat_map([], fun)
    |> Enum.reverse()
  end

  defp recur_flat_map(leaf, acc, fun) do
    case Tree.Def.impl_for(leaf) do
      nil ->
        [fun.(leaf) | acc]

      _ ->
        Tree.Def.reduce(leaf, acc, &recur_flat_map(&1, &2, fun))
    end
  end

  @doc """
  Applies the given function to each leaf in the data structure
  and returns a flat list of transformed leaves with an accumulator.

  ## Examples

      iex> Tree.flat_map_reduce([1, 2, 3], 0, fn x, acc -> {x + 1, x + acc} end)
      {[2, 3, 4], 6}

      iex> Tree.flat_map_reduce([{1, 2}, %{a: 3}], 0, fn x, acc -> {x + 1, x + acc} end)
      {[2, 3, 4], 6}
  """
  def flat_map_reduce(tree, acc, fun) do
    {mapped, acc} = recur_flat_map_reduce(tree, {[], acc}, fun)
    {Enum.reverse(mapped), acc}
  end

  defp recur_flat_map_reduce(leaf, {map_acc, acc}, fun) do
    case Tree.Def.impl_for(leaf) do
      nil ->
        {elem, acc} = fun.(leaf, acc)
        {[elem | map_acc], acc}

      _ ->
        Tree.Def.reduce(leaf, {map_acc, acc}, &recur_flat_map_reduce(&1, &2, fun))
    end
  end

  @doc """
  Returns the leaves of a tree-like data structure as
  a list.

  ## Examples

      iex> Tree.leaves([1, 2, 3])
      [1, 2, 3]

      iex> Tree.leaves([1, {2, 3, %{a: 4, b: 5}}, [6]])
      [1, 2, 3, 4, 5, 6]
  """
  def leaves(tree) do
    all_leaves = recur_leaves(tree, [])
    Enum.reverse(all_leaves)
  end

  def recur_leaves(leaf, acc) do
    case Tree.Def.impl_for(leaf) do
      nil ->
        [leaf | acc]

      _ ->
        Tree.Def.reduce(leaf, acc, &recur_leaves/2)
    end
  end

  @doc """
  Applies the given function to every leaf in the
  data structure.

  ## Examples

      iex> Tree.map([1, 2, 3], fn x -> x + 1 end)
      [2, 3, 4]

      iex> Tree.map([{1, 2}, %{a: 3, b: {4}}], fn x -> x + 1 end)
      [{2, 3}, %{a: 4, b: {5}}]
  """
  def map(tree, fun) do
    {container, :ok} = Tree.Def.traverse(tree, :ok, &recur_map(&1, &2, fun))
    container
  end

  defp recur_map(leaf, :ok, fun) do
    case Tree.Def.impl_for(leaf) do
      nil ->
        {fun.(leaf), :ok}

      _ ->
        {map(leaf, fun), :ok}
    end
  end

  @doc """
  Applies the given function to every leaf in the
  data structure, carrying along the given accumulator.

  ## Examples

      iex> Tree.map_reduce([1, 2, 3], 0, fn x, acc -> {x + 1, x + acc} end)
      {[2, 3, 4], 6}

      iex> Tree.map_reduce([{1, 2}, %{a: 3}], 0, fn x, acc -> {x + 1, x + acc} end)
      {[{2, 3}, %{a: 4}], 6}
  """
  def map_reduce(tree, acc, fun) do
    Tree.Def.traverse(tree, acc, &recur_map_reduce(&1, &2, fun))
  end

  defp recur_map_reduce(leaf, acc, fun) do
    case Tree.Def.impl_for(leaf) do
      nil ->
        fun.(leaf, acc)

      _ ->
        map_reduce(leaf, acc, fun)
    end
  end

  @doc """
  Applies the given function to every leaf in the
  data structure, carrying along the accumulator.

  ## Examples

      iex> Tree.reduce([1, 2, 3], 0, fn x, acc -> x + acc end)
      6

      iex> Tree.reduce([{1, 2}, %{a: 3}], 0, fn x, acc -> x + acc end)
      6
  """
  def reduce(tree, acc, fun) do
    Tree.Def.reduce(tree, acc, &recur_reduce(&1, &2, fun))
  end

  defp recur_reduce(leaf, acc, fun) do
    case Tree.Def.impl_for(leaf) do
      nil ->
        fun.(leaf, acc)

      _ ->
        reduce(leaf, acc, fun)
    end
  end

  @doc """
  Zips corresponding leaves in two tree-like data structures
  and applies the given function to the pairs.

  Trees which have the same nesting structure, but different
  containers will take on the containers of the left tree.

  ## Examples

      iex> Tree.zip_with([1, 2, 3], [4, 5, 6], fn x, y -> x + y end)
      [5, 7, 9]

      iex> Tree.zip_with([{1, 2}, [3]], {[4, 5], {6}}, fn x, y -> x + y end)
      [{5, 7}, [9]]
  """
  def zip_with(left_tree, right_tree, fun) do
    right_semi_flat =
      right_tree
      |> Tree.Def.reduce([], fn x, acc -> [x | acc] end)
      |> Enum.reverse()

    case Tree.Def.traverse(left_tree, right_semi_flat, &recur_zip_with(&1, &2, fun)) do
      {zipped, []} ->
        zipped

      _ ->
        raise ArgumentError,
              "left and right tree structures are not compatible and" <>
                " could not be zipped"
    end
  end

  defp recur_zip_with(left, [right | rest_right], fun) do
    case {Tree.Def.impl_for(left), Tree.Def.impl_for(right)} do
      {nil, nil} ->
        {fun.(left, right), rest_right}

      {nil, _} ->
        raise ArgumentError,
              "left and right tree structures are not compatible and" <>
                " could not be zipped"

      {_, nil} ->
        raise ArgumentError,
              "left and right tree structures are not compatible and" <>
                " could not be zipped"

      {_, _} ->
        {zip_with(left, right, fun), rest_right}
    end
  end

  @doc """
  Zips corresponding leaves in two tree-like data structures
  and applies the given function to the pairs with an accumulator.

  ## Examples

      iex> Tree.zip_reduce([1, 2, 3], [4, 5, 6], 0, fn x, y, acc -> x + y + acc end)
      21

      iex> Tree.zip_reduce([{1, 2}, [3]], {[4, 5], {6}}, 0, fn x, y, acc -> x + y + acc end)
      21
  """
  def zip_reduce(left_tree, right_tree, acc, fun) do
    right_semi_flat =
      right_tree
      |> Tree.Def.reduce([], fn x, acc -> [x | acc] end)
      |> Enum.reverse()

    case Tree.Def.reduce(left_tree, {acc, right_semi_flat}, &recur_zip_reduce(&1, &2, fun)) do
      {accumulated, []} ->
        accumulated

      _ ->
        raise ArgumentError,
              "left and right tree structures are not compatible and" <>
                " could not be zipped"
    end
  end

  defp recur_zip_reduce(left, {acc, [right | rest_right]}, fun) do
    case {Tree.Def.impl_for(left), Tree.Def.impl_for(right)} do
      {nil, nil} ->
        {fun.(left, right, acc), rest_right}

      {nil, _} ->
        raise ArgumentError,
              "left and right tree structures are not compatible and" <>
                " could not be zipped"

      {_, nil} ->
        raise ArgumentError,
              "left and right tree structures are not compatible and" <>
                " could not be zipped"

      {_, _} ->
        {zip_reduce(left, right, acc, fun), rest_right}
    end
  end
end
