defmodule Features.Test do
  @moduledoc """
  To test featured code you have to set features property to enable runtime execution (it replaces the compile-time deletion).

  On `test.exs`:
      config :features, test: true

  On `test_helpers.exs`:
      Features.Test.start()

  On a test:
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
  """
  use Agent, restart: :temporary

  defmacro __using__(_) do
    quote do
      require Features.Test
      import Features.Test
    end
  end

  @doc """
      featured_test "test2", features: [:a_feature] do
        assert MyModule.do_something() == :another_feature_is_disabled
      end
  """
  defmacro featured_test(test_description, opts \\ [], do: test_block) do
    features = opts[:features]

    quote do
      test unquote(test_description) do
        Features.Test.set_features(self(), unquote(features))
        unquote(test_block)
        Features.Test.reset_features(self())
      end
    end
  end

  def start, do: start_link([])

  @doc false
  def start_link(_opts) do
    {:ok, pid} = Agent.start_link(fn -> %{} end)
    Process.register(pid, :features__test)
    {:ok, pid}
  end

  @doc false
  def enabled?(feature), do: feature in get_features(self())

  @doc false
  def disabled?(feature), do: feature not in get_features(self())

  @doc false
  def set_features(process, features),
    do: Agent.update(Process.whereis(:features__test), &Map.put(&1, process, features))

  @doc false
  def reset_features(process),
    do: Agent.get_and_update(Process.whereis(:features__test), &Map.pop(&1, process))

  @doc false
  defp get_features(process) do
    Agent.get(Process.whereis(:features__test), &Map.get(&1, process))
  end
end
