if Code.ensure_loaded?(StreamData) do
  defmodule StreamTemporal.Gen do
    @moduledoc """
    Property-based testing helpers for temporal stream operations.

    This module provides generators and combinators for testing temporal stream transformations
    using StreamData. It allows you to define properties about how temporal operations behave
    over streams of data, making it easier to verify correctness of `StreamTemporal` functions.

    ## Examples

    ```elixir
    import StreamData
    import StreamTemporal.Gen

    # Test that always/3 inserts a value when the predicate is met
    property "always inserts when predicate is met" do
      check all list <- list_of(integer()),
                pred <- fn acc -> length(acc) >= 2 end,
                value <- integer() do
        result = StreamTemporal.always(list, value, pred) |> Enum.to_list()
        # Assertions about the result...
      end
    end

    # Using the leads_to operator for temporal properties
    property "next/3 adds value after matching elements" do
      check all list <- list_of(integer()),
                pred <- fn x -> x == 2 end,
                value <- integer() do
        result = StreamTemporal.next(list, value, pred) |> Enum.to_list()
        # Assertions about the result...
      end
    end
    ```

    The module provides several useful functions for expressing temporal properties:

    * `leads_to/4` - Expresses that one condition leads to another in a temporal sequence
    * `for_all/2` and `every/2` - Quantifiers for expressing properties over all elements
    * `always/2` - Generator for temporal "always" properties
    * `none_after/1` - Generator for temporal "none after" properties
    * `eventually/2` - Generator for temporal "eventually" properties
    * `bind_always/3` - Binds a generator to an always property with a predicate
    * `bind_none_after/2` - Binds a generator to ensure no elements occur after a predicate is met
    * `bind_eventually/3` - Binds a generator to an eventually property with a predicate
    """

    import StreamData

    @doc """
    Expresses that a temporal property leads to another condition.

    This function binds a generator to a temporal operation based on a predicate.
    It's used to express that when a certain condition is met, it leads to a specific
    temporal transformation.

    ## Parameters

    * `gen` - The generator to bind
    * `:for_all` - The quantifier type (currently only supports :for_all)
    * `pred` - The predicate function that determines when the condition is met
    * `operation` - The operation to apply when the predicate is satisfied

    ## Examples

        iex> import StreamData
        iex> import StreamTemporal.Gen
        iex> gen = list_of(integer())
        iex> pred = fn x -> x > 0 end
        iex> operation = fn list, pred -> Enum.filter(list, pred) end
        iex> _result = leads_to(gen, :for_all, pred, operation)
        iex> # Result is a generator that applies the operation when pred is met
    """
    def leads_to(gen, :for_all, pred, operation) when is_function(pred) do
      bind(gen, fn list when is_list(list) -> operation.(list, pred) end)
      |> normalize()
    end

    def leads_to(gen, :for_all, pred, operation), do: leads_to(gen, :for_all, eq(pred), operation)

    @doc """
    Infix operator for expressing temporal leads_to relationships.

    This operator provides a more natural syntax for expressing temporal logic
    relationships between predicates and operations. It's equivalent to calling
    `leads_to/4` but with a more fluent API.

    ## Parameters

    * `a` - The predicate or condition that must be met
    * `b` - The operation to perform when the condition is met

    ## Examples

        iex> import StreamData
        iex> import StreamTemporal.Gen
        iex> gen = list_of(integer())
        iex> pred = fn x -> x > 0 end
        iex> operation = fn list, pred -> Enum.filter(list, pred) end
        iex> _result = gen ~> pred ~> operation
        iex> # More fluent way of expressing leads_to relationships
    """
    def a ~> b, do: &leads_to(&1, &2, a, b)

    @doc """
    Universal quantifier for temporal properties.

    This function applies a temporal property to all elements in a generated stream.
    It's used to express that a certain condition should hold for all elements in
    the generated data.

    ## Parameters

    * `g` - The generator to apply the property to
    * `f` - The function that defines the temporal property

    ## Examples

        iex> import StreamData
        iex> import StreamTemporal.Gen
        iex> gen = list_of(integer())
        iex> property = fn _g, _quantifier -> always(integer()) end
        iex> _result = for_all(gen, property)
    """
    def for_all(g, f), do: f.(g, :for_all)

    @doc """
    Universal quantifier for temporal properties (alternative name).

    This function is an alternative to `for_all/2` and serves the same purpose.
    It applies a temporal property to all elements in a generated stream.

    ## Parameters

    * `g` - The generator to apply the property to
    * `f` - The function that defines the temporal property

    ## Examples

        iex> import StreamData
        iex> import StreamTemporal.Gen
        iex> gen = list_of(integer())
        iex> property = fn _g, _quantifier -> always(integer()) end
        iex> _result = every(gen, property)
    """
    def every(g, f), do: f.(g, :every)

    @doc """
    Binds a generator to an always property with a predicate.

    This function combines a generator with an "always" temporal property, ensuring
    that a certain condition is always met when the predicate is satisfied.

    ## Parameters

    * `gen` - The base generator
    * `pred` - The predicate function that determines when the condition should be applied
    * `some_gen` - The generator for the value to insert when the predicate is met

    ## Examples

        iex> import StreamData
        iex> import StreamTemporal.Gen
        iex> gen = list_of(integer())
        iex> pred = fn acc -> length(acc) >= 2 end
        iex> value_gen = integer()
        iex> _result = bind_always(gen, pred, value_gen)
    """
    def bind_always(gen, pred, some_gen), do: for_all(gen, pred ~> always(some_gen))

    @doc """
    Generator for temporal "always" properties.

    Creates a generator that, when a predicate is met on a list, will insert a value
    generated by some_gen at the point where the predicate is first satisfied.
    """
    def always(some_gen, mapper \\ &__MODULE__.default_mapper/2) do
      fn list, pred ->
        case Enum.find_index(list, pred) do
          nil ->
            constant(list)

          idx ->
            tuple(
              {list |> Enum.slice(0..idx) |> constant(),
               some_gen
               |> map(fn new_value -> list |> Enum.at(idx) |> mapper.(new_value) end)
               |> list_of()
               |> nonempty()}
            )
        end
      end
    end

    @doc """
    Binds a generator to ensure no elements occur after a predicate is met.

    This function creates a temporal property that ensures no elements appear
    in the stream after a certain predicate condition is satisfied.

    ## Parameters

    * `gen` - The base generator
    * `pred` - The predicate function that determines when no more elements should appear

    ## Examples

        iex> import StreamData
        iex> import StreamTemporal.Gen
        iex> gen = list_of(integer())
        iex> pred = fn x -> x < 0 end
        iex> _result = bind_none_after(gen, pred)
    """
    def bind_none_after(gen, pred), do: for_all(gen, none_after(pred))

    @doc """
    Generator for temporal "none after" properties.

    Creates a generator that ensures no elements occur after a predicate is first satisfied.
    """
    def none_after(pred) do
      fn gen, :for_all ->
        bind(gen, &handle_none_after(&1, pred, gen))
      end
    end

    defp handle_none_after(list, pred, gen) do
      case Enum.find_index(list, pred) do
        nil ->
          constant(list)

        idx ->
          [
            list |> Enum.slice(0..idx) |> constant(),
            gen |> filter(&(not pred.(&1))) |> list_of()
          ]
          |> fixed_list()
      end
    end

    @doc """
    Binds a generator to an eventually property with a predicate.

    This function combines a generator with an "eventually" temporal property, ensuring
    that a certain condition will eventually be met when the predicate is satisfied.

    ## Parameters

    * `gen` - The base generator
    * `pred` - The predicate function that determines when the condition should be applied
    * `some_gen` - The generator for the value to insert when the predicate is met

    ## Examples

        iex> import StreamData
        iex> import StreamTemporal.Gen
        iex> gen = list_of(integer())
        iex> pred = fn x -> x > 10 end
        iex> value_gen = integer()
        iex> _result = bind_eventually(gen, pred, value_gen)
    """
    def bind_eventually(gen, pred, some_gen), do: for_all(gen, pred ~> eventually(some_gen))

    @doc """
    Generator for temporal "eventually" properties.

    Creates a generator that, when a predicate is met on a list, will insert a value
    generated by some_gen at a random position after elements that satisfy the predicate.

    ## Parameters

    * `some_gen` - The generator for values to insert
    * `mapper` - A function to map the trigger value and resultant value (defaults to `default_mapper/2`)

    ## Examples

        iex> import StreamData
        iex> import StreamTemporal.Gen
        iex> gen = integer()
        iex> _result = eventually(gen)
    """
    def eventually(some_gen, mapper \\ &default_mapper/2) do
      fn list, pred ->
        handle_eventually(list, pred, some_gen, mapper)
      end
    end

    defp handle_eventually(list, pred, some_gen, mapper) do
      case Enum.find_index(list, pred) do
        nil ->
          constant(list)

        _ ->
          list
          |> Enum.with_index()
          |> Enum.filter(fn {v, _i} -> pred.(v) end)
          |> Enum.reduce({list |> Enum.map(&constant/1), 1}, &process_eventually_element(&1, &2, some_gen, mapper))
          |> elem(0)
          |> fixed_list()
      end
    end

    defp process_eventually_element({value, index}, {l, offset}, some_gen, mapper) do
      {
        List.insert_at(
          l,
          Enum.random((index + offset)..length(l)),
          map(some_gen, fn new_value -> mapper.(value, new_value) end)
        ),
        offset + 1
      }
    end

    @doc """
    Binds a generator to a next property with a predicate.

    This function creates a temporal property that inserts a value generated by `some_gen`
    immediately after each element that satisfies the predicate `pred`.

    ## Parameters

    * `gen` - The base generator
    * `pred` - The predicate function that determines which elements should be followed by a value
    * `some_gen` - The generator for the value to insert after elements that satisfy the predicate

    ## Examples

        iex> import StreamData
        iex> import StreamTemporal.Gen
        iex> gen = list_of(integer())
        iex> pred = fn x -> x == 2 end
        iex> value_gen = integer()
        iex> _result = bind_next(gen, pred, value_gen)
    """
    def bind_next(gen, pred, some_gen) when is_function(pred),
      do: for_all(gen, pred ~> next(some_gen))

    @doc """
    Generator for temporal "next" properties.

    Creates a generator that, when a predicate is met on a list, will insert a value
    generated by `some_gen` immediately after each element that satisfies the predicate.

    ## Parameters

    * `some_gen` - The generator for values to insert after matching elements
    * `mapper` - A function to map the trigger value and resultant value (defaults to `default_mapper/2`)

    ## Examples

        iex> import StreamData
        iex> import StreamTemporal.Gen
        iex> gen = integer()
        iex> _result = next(gen)
    """
    def next(some_gen, mapper \\ &default_mapper/2) do
      fn list, pred ->
        handle_next(list, pred, some_gen, mapper)
      end
    end

    defp handle_next(list, pred, some_gen, mapper) do
      case Enum.find_index(list, pred) do
        nil ->
          constant(list)

        _ ->
          list
          |> Enum.with_index()
          |> Enum.filter(fn {v, _i} -> pred.(v) end)
          |> Enum.reduce({Enum.map(list, &constant/1), 1}, &process_next_element(&1, &2, some_gen, mapper))
          |> elem(0)
          |> fixed_list()
      end
    end

    defp process_next_element({value, index}, {l, offset}, some_gen, mapper) do
      {
        List.insert_at(
          l,
          index + offset,
          map(some_gen, fn new_value -> mapper.(value, new_value) end)
        ),
        offset + 1
      }
    end

    @doc """
    Binds a generator to a starts_with property.

    This function creates a temporal property that ensures a generated list starts
    with a value from the specified generator.

    ## Parameters

    * `gen` - The base generator
    * `some_gen` - The generator for the value to prepend when the list should start with a value

    ## Examples

        iex> import StreamData
        iex> import StreamTemporal.Gen
        iex> gen = list_of(integer())
        iex> value_gen = integer()
        iex> _result = bind_starts_with(gen, value_gen)
    """
    def bind_starts_with(gen, some_gen), do: every(gen, starts_with(some_gen))

    @doc """
    Generator for temporal "starts_with" properties.

    Creates a generator that, when applied to a list, will prepend a value
    generated by some_gen to the beginning of the list. This is used to ensure
    that generated lists start with specific values based on temporal conditions.

    ## Parameters

    * `some_gen` - The generator for values to prepend to lists

    ## Examples

        iex> import StreamData
        iex> import StreamTemporal.Gen
        iex> gen = integer()
        iex> _result = starts_with(gen)
        iex> # Creates a generator that can prepend values to lists
    """
    def starts_with(some_gen) do
      fn gen, :every ->
        boolean()
        |> bind(&handle_starts_with(&1, gen, some_gen))
      end
    end

    defp handle_starts_with(always, gen, some_gen) do
      gen
      |> bind(&process_starts_with(&1, always, some_gen))
    end

    defp process_starts_with(list, always, some_gen) do
      case {list, always} do
        {[], false} -> constant(list)
        _ -> bind(some_gen, fn head -> constant([head | list]) end)
      end
    end

    @doc """
    Binds a generator to an ends_with property.

    This function creates a temporal property that ensures a generated list ends
    with a value from the specified generator.

    ## Parameters

    * `gen` - The base generator
    * `some_gen` - The generator for the value to append when the list should end with a value

    ## Examples

        iex> import StreamData
        iex> import StreamTemporal.Gen
        iex> gen = list_of(integer())
        iex> value_gen = integer()
        iex> _result = bind_ends_with(gen, value_gen)
    """
    def bind_ends_with(gen, some_gen), do: every(gen, ends_with(some_gen))

    @doc """
    Generator for temporal "ends_with" properties.

    Creates a generator that, when applied to a list, will append a value
    generated by some_gen to the end of the list. This is used to ensure
    that generated lists end with specific values based on temporal conditions.
    The generator makes a probabilistic choice about whether to always append
    the value or only append it conditionally.

    ## Parameters

    * `some_gen` - The generator for values to append to lists

    ## Examples

        iex> import StreamData
        iex> import StreamTemporal.Gen
        iex> gen = integer()
        iex> _result = ends_with(gen)
        iex> # Creates a generator that can append values to lists
    """
    def ends_with(some_gen) do
      fn gen, :every ->
        boolean()
        |> bind(&handle_ends_with(&1, gen, some_gen))
      end
    end

    defp handle_ends_with(always, gen, some_gen) do
      bind(gen, &process_ends_with(&1, always, some_gen))
    end

    defp process_ends_with(list, always, some_gen) do
      case {list, always} do
        {[], false} -> constant(list)
        _ -> bind(some_gen, fn tail -> constant(list ++ [tail]) end)
      end
    end

    @doc """
    Default mapper function for temporal generators.

    This function is used as the default mapper in temporal generators to transform
    trigger values to resultant values.

    ## Parameters

    * `trigger_value` - The value that triggered the temporal condition
    * `resultant_value` - The value to be inserted as a result

    ## Examples

        iex> StreamTemporal.Gen.default_mapper(5, 10)
        10
    """
    def default_mapper(_trigger_value, resultant_value), do: resultant_value

    def eq(a), do: &(&1 == a)
    defp normalize(f), do: bind(f, &do_normalize/1)
    defp do_normalize({a, b}), do: constant(a ++ b)
    defp do_normalize(f), do: constant(f)
  end
end
