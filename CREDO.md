# Credo

Credo is a static code analysis tool for Elixir that helps improve code consistency and find potential refactoring opportunities.

## Running Credo

To run credo on this project:

```bash
mix credo
```

This will analyze the code and report any issues according to the configured checks.

## Configuration

The configuration file is located at `.credo.exs`. It includes various checks for consistency, design, readability, refactoring opportunities, and warnings.

To run credo with strict mode (includes low priority checks):

```bash
mix credo --strict
```

## Common Tasks

- To fix issues: Address the specific warnings and suggestions provided by credo
- To disable specific checks: Modify the `.credo.exs` file
- To learn about a specific issue: `mix credo explain <issue>`