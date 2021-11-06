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

## Usage

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
    :a_feature_is_enabled

    # this will enable the next statement if :another_feature is in config
    @feature :another_feature
    :another_feature_is_enabled

    # this will enable the next statement if :another_feature is not in config
    @feature_off :another_feature
    :another_feature_is_disabled
  end
end
```

Code is automatically removed during compilation if the feature condition is not met.
### Testing

To test featured code you have to set features property to enable runtime execution (it replaces the compile-time deletion).

On `test.exs`:
```elixir
config :features, test: true
```

On `test_helpers.exs`:

```elixir
Features.Test.start()
```

On a test:

```elixir
defmodule MyModuleTest do
  use ExUnit.Case, async: true
  use Features.Test

  featured_test "test1", features: [:a_feature, :another_feature] do
    assert MyModule.do_something() == :another_feature_is_enabled
  end

  featured_test "test2", features: [:a_feature] do
    assert MyModule.do_something() == :another_feature_is_disabled
  end

  featured_test "test3", features: [] do
    assert_raise CaseClauseError, fn -> MyModule.do_something() end
  end
end
```
