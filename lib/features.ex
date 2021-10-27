defmodule Features do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      @enabled_features Application.compile_env!(:features, :features)

      require Features
      import Features
    end
  end

  defmacro no_feature(feature, do: rest) do
    quote do
      if unquote(feature) not in @enabled_features do
        unquote(rest)
      end
    end
  end

  defmacro feature(feature, do: rest) do
    quote do
      if unquote(feature) in @enabled_features do
        unquote(rest)
      end
    end
  end
end
