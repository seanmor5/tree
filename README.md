# Tree

Small library for working with nested tree-like data structures.

Each tree-like data structure implements the `Tree.Def` protocol which provides implementations for traversing and reducing the nested tree-like data structure. There are default implementations for `List`, `Tuple`, and `Map`.

## Installation

```elixir
def deps do
  [
    {:tree, "~> 0.1.0", github: "seanmor5/tree"}
  ]
end
```

## Examples

Consider the following complex nested data structure:

```elixir
tree = %{a: {1, [2, 3]}, b: [%{c: {2, 3}, d: [5]}], c: %{d: [6, {7, 8}, 9]}}
```

`Tree` treats values which don't implement the `Tree.Def` protocol as leaves, so you can apply arbitrary transformations and reductions to leaves without having to deal with nesting. Most functions you're familiar with in `Enum` work in `Tree`:

```elixir
Tree.map(tree, fn x -> x + 1 end)
# %{a: {2, [3, 4]}, b: [%{c: {3, 4}, d: [6]}], c: %{d: [7, {8, 9}, 10]}}
```

```elixir
Tree.reduce(tree, 0, fn x, acc -> x + acc end)
# 46
```

```elixir
Tree.flat_map(tree, fn x -> x + 1 end)
[2, 3, 4, 3, 4, 6, 7, 8, 9, 10]
```

If you have multiple nested data structures with the same tree-like structure, you can easily apply `zip_with/3` or `zip_reduce/4` to transform the trees as a pair:

```elixir
tree1 = %{a: {1, [2, 3]}, b: [%{c: {2, 3}, d: [5]}], c: %{d: [6, {7, 8}, 9]}}
tree2 = %{a: {9, [10, 11]}, b: [%{c: {12, 13}, d: [14]}], c: %{d: [15, {16, 17}, 18]}}
Tree.zip_with(tree1, tree2, fn x, y -> x + y end)
# %{a: {10, [12, 14]}, b: [%{c: {14, 16}, d: [19]}], c: %{d: [21, {23, 25}, 27]}}
```

```elixir
tree1 = %{a: {1, [2, 3]}, b: [%{c: {2, 3}, d: [5]}], c: %{d: [6, {7, 8}, 9]}}
tree2 = %{a: {9, [10, 11]}, b: [%{c: {12, 13}, d: [14]}], c: %{d: [15, {16, 17}, 18]}}
Tree.zip_reduce(tree1, tree2, 0, fn x, y, acc -> x + y + acc end)
# 181
```