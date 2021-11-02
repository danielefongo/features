defmodule Features.Test do
  use Agent, restart: :temporary

  defmacro __using__(_) do
    quote do
      require Features.Test
      import Features.Test
    end
  end

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

  def start_link(_opts) do
    {:ok, pid} = Agent.start_link(fn -> %{} end)
    Process.register(pid, :features__test)
    {:ok, pid}
  end

  def enabled?(feature), do: feature in get_features(self())
  def disabled?(feature), do: feature not in get_features(self())

  def set_features(process, features),
    do: Agent.update(Process.whereis(:features__test), &Map.put(&1, process, features))

  def reset_features(process),
    do: Agent.get_and_update(Process.whereis(:features__test), &Map.pop(&1, process))

  defp get_features(process) do
    Agent.get(Process.whereis(:features__test), &Map.get(&1, process))
  end
end
