# Agent Guide for StreamTemporal

This document provides essential information for agents working with the StreamTemporal Elixir project.

## Project Overview

StreamTemporal is an Elixir library that provides stream transformation functions with temporal logic capabilities. It extends Elixir's Stream module with functions that allow you to manipulate enumerables based on temporal conditions.

## Code Organization

```
lib/
  stream_temporal.ex     # Main module with stream transformation functions
test/
  stream_temporal_test.exs  # Tests for the main module
mix.exs                 # Project configuration
.formatter.exs          # Code formatting configuration
.gitignore              # Git ignore rules
AGENTS.md               # Agent guide
```

## Essential Commands

### Build and Dependencies
```bash
mix deps.get     # Fetch dependencies
mix compile      # Compile the project
```

### Testing
```bash
mix test         # Run tests
mix test --cover # Run tests with coverage
```

### Code Quality
```bash
mix format       # Format code according to .formatter.exs
mix dialyzer     # Static analysis
```

### Documentation
```bash
mix docs         # Generate documentation (if ex_doc is added as dependency)
```

## Code Structure and Patterns

### Main Module Structure
The `StreamTemporal` module contains several functions that extend Elixir's Stream capabilities:

1. `starts_with/2` - Adds a value at the beginning of a stream
2. `ends_with/3` - Adds a value at the end of a stream based on a predicate
3. `next/3` - Adds a value after elements that match a predicate
4. `always/3` - Adds a value when a predicate is met based on the accumulated values

### Function Patterns
- Functions typically follow the pattern of taking an enumerable as the first parameter
- Most functions leverage `Stream.transform/4` for stream manipulation
- Functions often have multiple clauses to handle different arities or types
- Many functions accept anonymous functions as parameters for dynamic value generation

### Naming Conventions
- Function names use snake_case as per Elixir conventions
- Predicate functions are typically named with a `pred` parameter
- Functions that accept functions as parameters often have multiple clauses to handle different function arities

## Testing Approach

The project uses ExUnit for testing:

- Tests are located in the `test/` directory
- Each test file corresponds to a module in `lib/`
- Tests use the `use ExUnit.Case` macro
- Doctests are enabled with `doctest ModuleName`

The current test suite is minimal and needs expansion to properly cover the functionality.

## Important Gotchas and Non-Obvious Patterns

1. **Stream Transformation**: The library heavily relies on `Stream.transform/4` which is a powerful but less commonly used Elixir function for stream manipulation.

2. **Function Identity**: Many functions use `&Function.identity/1` as the final reducer function in stream transformations.

3. **Anonymous Functions**: Several functions accept anonymous functions for dynamic value generation, with multiple clauses to handle different function arities (0-arity and 1-arity functions).

4. **Reference-based State Management**: The `next/3` function uses `make_ref()` for unique reference generation to manage state in stream transformations.

5. **Accumulator-based Predicates**: The `always/3` function uses an accumulator-based approach to determine when to insert values, with the predicate function receiving the accumulated values so far.

## Project-Specific Context

This library focuses on temporal stream operations - that is, operations that depend on timing or ordering within a stream rather than just the values themselves. The functions allow you to:

- Insert values at specific temporal positions in a stream
- Conditionally insert values based on predicates
- Transform streams based on previous elements

The library heavily uses `Stream.transform/4` for implementing these temporal operations, leveraging its ability to maintain state across stream elements. Each function implements different temporal logic patterns:

- `starts_with/2`: Temporal "beginning" insertion
- `ends_with/3`: Temporal "end" insertion with early termination capability
- `next/3`: Temporal "next" insertion after matching elements
- `always/3`: Temporal "always" insertion based on accumulated state

## Dependencies

Currently, the project has no external dependencies beyond Elixir's standard library. The `mix.exs` file contains only the basic project configuration.