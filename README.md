# Features

Features is an elixir porting of [rust cargo features](https://doc.rust-lang.org/cargo/reference/features.html).

## Installation

Add `features` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:features, github: "danielefongo/features", branch: "main"}
  ]
end
```

## Example

On `config.exs`:

```elixir
config :features, features: [:a_feature]
```

On code:

```elixir
defmodule MyModule do
  use Features

  # this will enable the next function if :a_feature is in config
  @feature :a_feature
  def do_something do
    IO.puts("a_feature is enabled")

    # this will enable the next statement if :another_feature is in config
    @feature :another_feature
    IO.puts("another_feature is enabled")

    # this will enable the next statement if :another_feature is not in config
    @feature_off :another_feature
    IO.puts("another_feature is disabled")

    :ok
  end
end
```
