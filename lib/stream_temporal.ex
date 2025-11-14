defmodule StreamTemporal do
  @moduledoc """
  Stream transformation functions with temporal logic capabilities.

  This module extends Elixir's Stream module with functions that allow you to
  manipulate enumerables based on temporal conditions.
  """

  @typedoc """
  A function that takes no arguments and returns a value.
  """
  @type thunk(a) :: (-> a)

  @typedoc """
  A predicate function that takes one argument and returns a boolean.
  """
  @type predicate(a) :: (a -> boolean())

  @typedoc """
  A function that takes the accumulator and returns a value.
  """
  @type acc_function(a) :: ([a] -> a)

  @doc """
  Adds a value at the beginning of a stream.

  ## Examples

      iex> StreamTemporal.starts_with([1, 2, 3], 0) |> Enum.to_list()
      [0, 1, 2, 3]

      iex> StreamTemporal.starts_with([1, 2, 3], fn -> 0 end) |> Enum.to_list()
      [0, 1, 2, 3]
  """
  @spec starts_with(Enumerable.t(a), a | thunk(a)) :: Enumerable.t(a) when a: var
  def starts_with(enum, value) when is_function(value, 0) do
    enum
    |> Stream.transform(
      fn -> [value.()] end,
      fn
        i, [acc] -> {[acc, i], []}
        i, [] -> {[i], []}
      end,
      &Function.identity/1
    )
  end

  @spec starts_with(Enumerable.t(a), a) :: Enumerable.t(a) when a: var
  def starts_with(enum, value), do: starts_with(enum, fn -> value end)

  @doc """
  Adds a value at the end of a stream based on a predicate.

  ## Examples

      iex> StreamTemporal.ends_with([1, 2, 3], 4, fn _ -> false end) |> Enum.to_list()
      [1, 2, 3, 4]

      iex> StreamTemporal.ends_with([1, 2, 3], 4, fn _ -> true end) |> Enum.to_list()
      [4]

      iex> StreamTemporal.ends_with([1, 2, 3], fn -> 4 end, fn _ -> false end) |> Enum.to_list()
      [1, 2, 3, 4]
  """
  @spec ends_with(Enumerable.t(a), a | thunk(a), predicate(a)) :: Enumerable.t(a) when a: var
  def ends_with(enum, value, pred \\ fn _ -> false end)

  @spec ends_with(Enumerable.t(a), thunk(a), predicate(a)) :: Enumerable.t(a) when a: var
  def ends_with(enum, value, pred) when is_function(value, 0) and is_function(pred, 1) do
    val = value.()

    enum
    |> Stream.transform(
      fn -> [] end,
      fn i, acc ->
        cond do
          match?({:halted, _acc}, acc) ->
            {:halted, list} = acc
            {:halt, list}

          pred.(i) ->
            {[val], {:halted, [val | acc]}}

          true ->
            {[i], [i | acc]}
        end
      end,
      fn acc -> {[value.()], acc} end,
      &Function.identity/1
    )
  end

  @spec ends_with(Enumerable.t(a), a, predicate(a)) :: Enumerable.t(a) when a: var
  def ends_with(enum, value, pred), do: ends_with(enum, fn -> value end, pred)

  @doc """
  Adds a value after elements that match a predicate.

  ## Examples

      iex> StreamTemporal.next([1, 2, 3], 0, fn x -> x == 2 end) |> Enum.to_list()
      [1, 2, 0, 3]

      iex> StreamTemporal.next([1, 2, 3], fn -> 0 end, fn x -> x == 2 end) |> Enum.to_list()
      [1, 2, 0, 3]
  """
  @spec next(Enumerable.t(a), a | thunk(a), predicate(a)) :: Enumerable.t(a) when a: var
  def next(enum, value, pred) when is_function(value, 0) do
    enum
    |> Stream.transform(
      fn -> {false, value.()} end,
      fn i, {inserted, n} ->
        cond do
          inserted == true -> {[i], {true, n}}
          pred.(i) -> {[i, n], {true, n}}
          true -> {[i], {false, n}}
        end
      end,
      &Function.identity/1
    )
  end

  @spec next(Enumerable.t(a), a, predicate(a)) :: Enumerable.t(a) when a: var
  def next(enum, value, pred), do: next(enum, fn -> value end, pred)

  @doc """
  Adds a value when a predicate is met.

  ## Examples

      iex> StreamTemporal.always([1, 2, 3], 0, fn acc -> length(acc) >= 2 end) |> Enum.to_list()
      [1, 2, 0]

      iex> StreamTemporal.always([1, 2, 3], fn -> 0 end, fn acc -> length(acc) >= 2 end) |> Enum.to_list()
      [1, 2, 0]
  """
  @spec always(Enumerable.t(a), a | thunk(a), predicate(a)) :: Enumerable.t(a) when a: var
  @spec always(Enumerable.t(a), acc_function(a), predicate(a)) :: Enumerable.t(a) when a: var
  def always(enum, value, pred) when is_function(value, 0) and is_function(pred, 1) do
    enum
    |> Stream.transform(
      fn -> {value, []} end,
      fn
        _, {v, true} ->
          {[v], {v, true}}

        i, {expected, acc} ->
          if pred.(acc) do
            v = expected.()
            {[v], {v, true}}
          else
            {[i], {expected, acc ++ [i]}}
          end
      end,
      &Function.identity/1
    )
  end

  @spec always(Enumerable.t(a), acc_function(a), predicate(a)) :: Enumerable.t(a) when a: var
  def always(enum, value, pred) when is_function(value, 1) and is_function(pred, 1) do
    enum
    |> Stream.transform(
      fn -> {value, []} end,
      fn
        _, {v, true} ->
          {[v], {v, true}}

        i, {expected, acc} ->
          if pred.(acc) do
            v = expected.(acc)
            {[v], {v, true}}
          else
            {[i], {expected, acc ++ [i]}}
          end
      end,
      &Function.identity/1
    )
  end

  @spec always(Enumerable.t(a), a, predicate(a)) :: Enumerable.t(a) when a: var
  def always(enum, value, pred), do: always(enum, fn -> value end, pred)
end
