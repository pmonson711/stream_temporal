# StreamTemporal

StreamTemporal is an Elixir library that extends Elixir's Stream module with temporal logic capabilities. It provides functions for manipulating enumerables based on temporal conditions, allowing you to insert elements at specific positions in a stream based on predicates or accumulated values.

## Features

- **starts_with/2** - Add elements at the beginning of a stream
- **ends_with/3** - Add elements at the end of a stream with early termination capability
- **next/3** - Insert elements after matching elements
- **always/3** - Conditionally insert elements based on accumulated values

All functions work with both static values and dynamic functions for generating values.

## Installation

The package can be installed by adding `stream_temporal` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:stream_temporal, "~> 0.1.0"}
  ]
end
```

## Property-Based Testing

The library includes optional property-based testing helpers when `stream_data` is available:

```elixir
# Import the testing helpers
import StreamTemporal.Gen

# Generate test data with temporal properties
gen = list_of(integer()) ~> always(integer())
```

See the `StreamTemporal.Gen` module documentation for more details on property-based testing capabilities.

## Usage Examples

### starts_with/2

Add a value at the beginning of a stream:

```elixir
# With a static value
StreamTemporal.starts_with([1, 2, 3], 0) |> Enum.to_list()
# [0, 1, 2, 3]

# With a function for dynamic value generation
StreamTemporal.starts_with([1, 2, 3], fn -> :rand.uniform(10) end) |> Enum.to_list()
# [7, 1, 2, 3] (random value at the beginning)
```

### ends_with/3

Add a value at the end of a stream with early termination capability:

```elixir
# Add value at the end when predicate is false
StreamTemporal.ends_with([1, 2, 3], 4, fn _ -> false end) |> Enum.to_list()
# [1, 2, 3, 4]

# Stop early when predicate is true
StreamTemporal.ends_with([1, 2, 3], 4, fn x -> x == 2 end) |> Enum.to_list()
# [4]

# With a function for dynamic value generation
StreamTemporal.ends_with([1, 2, 3], fn -> :rand.uniform(10) end, fn _ -> false end) |> Enum.to_list()
# [1, 2, 3, 7] (random value at the end)
```

### next/3

Insert a value after elements that match a predicate:

```elixir
# Insert 0 after every element that equals 2
StreamTemporal.next([1, 2, 3], 0, fn x -> x == 2 end) |> Enum.to_list()
# [1, 2, 0, 3]

# Insert multiple values after matching elements
StreamTemporal.next([1, 2, 3, 2, 4], "X", fn x -> x == 2 end) |> Enum.to_list()
# [1, 2, "X", 3, 2, "X", 4]

# With a function for dynamic value generation
StreamTemporal.next([1, 2, 3], fn -> :rand.uniform(10) end, fn x -> x == 2 end) |> Enum.to_list()
# [1, 2, 7, 3] (random value inserted after 2)
```

### always/3

Insert a value when a predicate based on accumulated values is met:

```elixir
# Insert 0 when we've accumulated at least 2 elements
StreamTemporal.always([1, 2, 3], 0, fn acc -> length(acc) >= 2 end) |> Enum.to_list()
# [1, 2, 0]

# Insert value when sum reaches a threshold
StreamTemporal.always([1, 2, 3, 4], 99, fn acc -> Enum.sum(acc) >= 3 end) |> Enum.to_list()
# [1, 2, 99]

# With a function that uses the accumulator to generate the value
StreamTemporal.always([1, 2, 3, 4], fn acc -> Enum.sum(acc) end, fn acc -> length(acc) >= 2 end) |> Enum.to_list()
# [1, 2, 3] (sum of [1, 2] which is 3)

# With a function for dynamic value generation
StreamTemporal.always([1, 2, 3], fn -> :rand.uniform(10) end, fn acc -> length(acc) >= 2 end) |> Enum.to_list()
# [1, 2, 7] (random value inserted when condition is met)
```

## Use Cases

StreamTemporal is particularly useful for:

1. **Data Processing Pipelines**: Insert markers, headers, or footers at specific positions in data streams
2. **Stream Transformation**: Adding temporal markers or control signals based on content
3. **Conditional Stream Augmentation**: Dynamically insert elements based on accumulated context
4. **Protocol Implementation**: Implementing stream-based protocols that require specific element ordering
5. **Testing and Simulation**: Injecting specific values at predetermined points in data streams for testing
6. **Event Processing**: Adding metadata or control events based on temporal conditions in event streams

## Examples in Practice

### Data Pipeline with Headers and Footers

```elixir
# Add header and footer to a data stream
data = [1, 2, 3, 4, 5]

data
|> StreamTemporal.starts_with("START")
|> StreamTemporal.ends_with("END", fn _ -> false end)
|> Enum.to_list()
# ["START", 1, 2, 3, 4, 5, "END"]
```

### Conditional Event Markers

```elixir
# Add warning markers when temperature exceeds threshold
temperatures = [20, 25, 30, 35, 28, 40]

temperatures
|> StreamTemporal.next("WARNING", fn temp -> temp > 30 end)
|> Enum.to_list()
# [20, 25, 30, "WARNING", 35, 28, "WARNING", 40]
```

### Accumulation-Based Insertions

```elixir
# Insert checkpoint every 3 elements
data = [1, 2, 3, 4, 5, 6, 7, 8, 9]

data
|> StreamTemporal.always("CHECKPOINT", fn acc -> rem(length(acc), 3) == 0 and length(acc) > 0 end)
|> Enum.to_list()
# [1, 2, 3, "CHECKPOINT", 4, 5, 6, "CHECKPOINT", 7, 8, 9, "CHECKPOINT"]
```

## Documentation

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/stream_temporal>.

The library includes comprehensive documentation with:

- **API Reference**: Complete documentation for all functions with type specifications
- **Examples**: Working code examples for each function
- **Property-Based Testing**: Documentation for the `StreamTemporal.Gen` module when using StreamData
- **Doctests**: All examples are tested as doctests to ensure they work correctly

