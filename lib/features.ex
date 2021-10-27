defmodule Features do
  @moduledoc false

  import Kernel, except: [def: 2]

  defmacro __using__(_) do
    quote do
      import Kernel, except: [def: 2]

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

  defmacro def(call, expr) do
    quote do
      feature = Module.get_attribute(__MODULE__, :feature)
      feature_off = Module.get_attribute(__MODULE__, :feature_off)

      cond do
        feature != nil && feature_off != nil ->
          raise "Cannot use feature and feature_off"

        feature != nil ->
          if feature in @enabled_features do
            Kernel.def(unquote(call), unquote(expr))
          end

        feature_off != nil ->
          if feature_off not in @enabled_features do
            Kernel.def(unquote(call), unquote(expr))
          end

        true ->
          Kernel.def(unquote(call), unquote(expr))
      end

      Module.delete_attribute(__MODULE__, :feature)
      Module.delete_attribute(__MODULE__, :feature_off)
    end
  end
end
