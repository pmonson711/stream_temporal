if Code.ensure_loaded?(PropCheck) do
  defmodule StreamTemporal.Proper do
    @moduledoc """
    Property-based testing generators for temporal stream operations using PropCheck.

    This module provides PropCheck generators that create test data for verifying
    temporal stream transformations. It complements `StreamTemporal.Gen` by offering
    an alternative property-based testing approach using the PropCheck library.

    """
    use PropCheck

    @doc """
    Generates a list that starts with a specific value.

    Creates a PropCheck generator that produces lists where the first element
    is always the specified value, followed by a list generated from the base generator.

    ## Parameters

    - `gen` - The base generator for the rest of the list elements
    - `value` - The generator or literal value for the first element

    """
    def starts_with(gen, value) do
      let [first <- value, rest <- list(gen)] do
        [first | rest]
      end
    end

    @doc """
    Generates a list that ends with a specific value.

    Creates a PropCheck generator that produces lists where the last element
    is always the specified value, preceded by a list generated from the base generator.

    ## Parameters

    - `gen` - The base generator for the initial list elements
    - `value` - The generator or literal value for the last element

    """
    def ends_with(gen, value) do
      let [last <- value, list <- list(gen)] do
        list ++ [last]
      end
    end

    @doc """
    Generates a list where a value appears immediately after elements matching a predicate.

    This function is currently unimplemented and serves as a placeholder for future
    development of temporal "next" property generators.

    ## Parameters

    - `gen` - The base generator for list elements
    - `value` - The value to insert after matching elements
    - `pred` - A predicate function to determine insertion points

    ## Note

    This function is incomplete and will raise a compilation warning about unused variables.
    """
    def next(_gen, _value, _pred) do
      # TODO: Implement next/3 generator
      []
    end

    def always(gen, value, pred) when is_function(value, 0) do
      predicated_gen =
        let [f <- gen] do
          if pred.(f), do: value.(), else: f
        end

      list(predicated_gen)
    end

    def always(gen, value, pred) when is_function(value, 1) do
      predicated_gen =
        let [f <- gen] do
          if pred.(f), do: value.(f), else: f
        end

      list(predicated_gen)
    end

    def always(gen, value, pred) do
      predicated_gen =
        let [f <- gen, v <- value] do
          if pred.(f), do: v, else: f
        end

      list(predicated_gen)
    end
  end
end
