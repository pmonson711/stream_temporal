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

## Documentation

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/stream_temporal>.

## Continuous Integration

The project uses GitHub Actions for continuous integration with the following workflow:

### Test Matrix
- **Elixir versions**: 1.19, 1.20, 1.21
- **OTP versions**: 26.0, 27.0
- **Operating system**: Ubuntu Latest

### CI Pipeline
1. **Test Job**: Runs comprehensive tests across all supported versions
   - Dependency caching for faster builds
   - Compilation with warnings as errors
   - Credo code analysis
   - Dialyzer static analysis
   - Unit tests with coverage reporting
   - Documentation generation

2. **Lint Job**: Additional code quality checks
   - Format verification (ensures code is properly formatted)
   - Credo analysis (if not already run in test job)

3. **Security Job**: Security vulnerability checks
   - Dependency vulnerability audit using `mix hex.audit`
   - Dependency audit using `depaudit` (when available)

### Local Development

For local development, you can run the same checks as CI:

```bash
# Install dependencies
mix deps.get

# Run tests with coverage
mix test --cover

# Run static analysis
mix dialyzer

# Run code analysis
mix credo

# Check formatting
mix format --check-formatted

# Generate documentation
mix docs

# Run all quality checks
mix test && mix credo && mix dialyzer && mix format --check-formatted
```

