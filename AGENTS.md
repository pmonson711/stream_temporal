# Agent Guide for StreamTemporal

This document provides essential information for agents working with the StreamTemporal Elixir project.

## Project Overview

StreamTemporal is an Elixir library that provides stream transformation functions with temporal logic capabilities. It extends Elixir's Stream module with functions that allow you to manipulate enumerables based on temporal conditions.

## Code Organization

```
lib/
  stream_temporal.ex         # Main module with stream transformation functions
  stream_temporal/
    gen.ex                   # Property-based testing helpers with StreamData
test/
  stream_temporal_test.exs   # Main module tests
  stream_temporal/
    gen_test.exs             # Property-based tests for gen.ex module
mix.exs                     # Project configuration with dependencies
.formatter.exs               # Code formatting configuration
.credo.exs                  # Credo static analysis configuration
.gitignore                  # Git ignore rules
AGENTS.md                   # Agent guide
CREDO.md                    # Code quality guidelines
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
mix credo        # Run Credo static analysis
mix dialyzer     # Static analysis with Dialyzer
```

### Documentation
```bash
mix docs         # Generate documentation using ex_doc
```

### CI/CD
- GitHub Actions workflow setup (`.github/workflows/` directory exists but currently empty)
- Recommended CI pipeline should include: `mix format --check`, `mix credo`, `mix test --cover`, `mix dialyzer`

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

### Property-Based Testing Module
The `StreamTemporal.Gen` module provides advanced property-based testing helpers:

#### Core Functions
- `leads_to/4` - Expresses temporal relationships between predicates and operations
- `for_all/2` and `every/2` - Universal quantifiers for temporal properties
- `always/2` - Generator for temporal "always" properties
- `none_after/1` - Generator for temporal "none after" properties
- `eventually/2` - Generator for temporal "eventually" properties

#### Temporal Combinators
- `bind_always/3` - Binds a generator to an always property with a predicate
- `bind_none_after/2` - Ensures no elements occur after a predicate is met
- `bind_eventually/3` - Binds a generator to an eventually property with a predicate
- `bind_next/3` - Binds a generator to insert values after matching elements
- `bind_starts_with/2` - Binds a generator to prepend values to lists
- `bind_ends_with/2` - Binds a generator to append values to lists

#### Infix Operators
- `~>/2` - Infix operator for expressing temporal leads_to relationships (e.g., `gen ~> pred ~> operation`)

#### Utilities
- `default_mapper/2` - Default mapper function for temporal generators
- `eq/1` - Equality predicate generator

The module is conditionally loaded when StreamData is available (`Code.ensure_loaded?(StreamData)`).

### Naming Conventions
- Function names use snake_case as per Elixir conventions
- Predicate functions are typically named with a `pred` parameter
- Functions that accept functions as parameters often have multiple clauses to handle different function arities

### Code Quality Configuration
The project uses multiple static analysis tools:

#### Credo (.credo.exs)
- **Strict mode**: Disabled (can be enabled with `mix credo --strict`)
- **Consistency checks**: Exception names, line endings, parameter pattern matching, spacing
- **Readability checks**: Function names, module attributes, pipe operators, spacing conventions
- **Refactoring checks**: Complexity, nested conditions, redundant clauses
- **Warning checks**: Unused operations, application config, unsafe operations
- **Line length limit**: 120 characters (configurable via `max_length: 120`)

#### Dialyzer Configuration
Configured with strict flags for comprehensive type checking:
- `unmatched_returns` - Warns about ignored return values
- `error_handling` - Checks error handling patterns
- `underspecs` - Detects overspecification
- `overspecs` - Detects underspecification
- `missing_return` - Warns about missing return specifications
- `extra_return` - Warns about extra return values

#### Code Formatting (.formatter.exs)
- Standard Elixir formatter configuration
- Input files: `{mix,.formatter}.exs`, `{config,lib,test}/**/*.{ex,exs}`
- Import dependencies: `[:stream_data]` for property-based testing formatting

## Testing Approach

The project uses ExUnit for testing with two complementary approaches:

### Unit Testing
- Tests located in the `test/` directory with pattern-based naming (`*_test.exs`)
- Tests use the `use ExUnit.Case` macro
- Doctests are enabled with `doctest ModuleName` for both `StreamTemporal` and `StreamTemporal.Gen`
- Tests are organized using `describe` blocks for logical grouping
- Includes tests for edge cases and different code paths (e.g., triggered state handling)

### Property-Based Testing
- Uses `ExUnitProperties` for property-based testing
- Tests for `StreamTemporal.Gen` are in `test/stream_temporal/gen_test.exs`
- Tests use StreamData generators to test functions over many random inputs
- Includes temporal properties that verify behavior across different stream conditions
- Property tests verify invariants about temporal relationships (e.g., "always some_gen after pred")

### Test Configuration
- `test_helper.exs` sets up the ExUnit test environment
- Property tests use `check all` syntax from StreamData
- Some tests include timeout configurations (e.g., `@tag timeout: :infinity`)
- Tests support async execution with `use ExUnit.Case, async: true`

## Important Gotchas and Non-Obvious Patterns

### Core Stream Operations
1. **Stream Transformation**: The library heavily relies on `Stream.transform/4` which is a powerful but less commonly used Elixir function for stream manipulation.

2. **Function Identity**: Many functions use `&Function.identity/1` as the final reducer function in stream transformations.

3. **Anonymous Functions**: Several functions accept anonymous functions for dynamic value generation, with multiple clauses to handle different function arities (0-arity and 1-arity functions).

4. **Reference-based State Management**: The `next/3` function uses `make_ref()` for unique reference generation to manage state in stream transformations.

5. **Accumulator-based Predicates**: The `always/3` function uses an accumulator-based approach to determine when to insert values, with the predicate function receiving the accumulated values so far.

### Property-Based Testing Patterns
6. **Conditional Loading**: The `StreamTemporal.Gen` module is only available when StreamData is loaded (`Code.ensure_loaded?(StreamData)`). Always check for availability before using these functions.

7. **Infix Operator Overloading**: The `~>/2` operator is used for temporal leads_to relationships, providing a fluent API for property-based testing.

8. **Generator Composition**: Property-based testing functions follow a composable pattern where generators can be bound to temporal properties using functions like `bind_always/3`, `bind_next/3`, etc.

9. **Lazy Evaluation**: All temporal generators return functions that are only evaluated when the property is actually tested, allowing for complex temporal relationships.

### Type System Patterns
10. **Custom Type Definitions**: The module defines custom types:
    - `thunk(a)` - A function that takes no arguments and returns a value
    - `predicate(a)` - A predicate function that takes one argument and returns a boolean
    - `acc_function(a)` - A function that takes the accumulator and returns a value

11. **Type Specifications**: All public functions have comprehensive `@spec` definitions with proper type constraints and guards for different arities.

### Development Tool Integration
12. **Multiple Static Analysis Tools**: The project uses both Credo (style) and Dialyzer (type) analysis. Both should be run in CI to catch different classes of issues.

13. **Formatter Integration**: The `.formatter.exs` includes StreamData dependencies, which affects formatting of property-based test code.

14. **Documentation Testing**: Both doctest modules (`StreamTemporal` and `StreamTemporal.Gen`) are tested, so documentation examples must be valid Elixir code.

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

### Additional Files
- **CREDO.md**: Contains additional code quality guidelines and project-specific rules
- **.github/workflows/**: CI/CD configuration directory (currently empty but ready for GitHub Actions)

### Development Environment
- **Elixir Version**: Requires Elixir ~> 1.19
- **Optional Dependencies**: StreamData is optional - property-based testing functions gracefully handle when it's not available
- **Build System**: Uses standard Mix build system with comprehensive static analysis

### Testing Philosophy
The project emphasizes both traditional unit testing and property-based testing:
- Unit tests verify specific behavior and edge cases
- Property-based tests ensure temporal invariants hold across all possible inputs
- Combined approach provides comprehensive test coverage for temporal logic

This dual testing approach is particularly important for temporal operations where bugs can be subtle and context-dependent.

## Dependencies

The project includes several development dependencies:

- **dialyxir** (~> 1.0) - Static analysis and type checking
- **ex_doc** (~> 0.34) - Documentation generation  
- **credo** (~> 1.7) - Static code analysis and linting
- **stream_data** (~> 1.0, optional) - Property-based testing generators

Runtime dependencies:
- **logger** (built-in) - Elixir logging framework

All development dependencies have `only: [:dev, :test]` and `runtime: false` to avoid polluting the production runtime.