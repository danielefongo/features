defmodule Features do
  @moduledoc """
  Features enables or disables code sections with annotation.

  ## Example
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

  Code is automatically removed during compilation if the feature condition is not met.

  A config example is the following:
      config :features, features: [:a_feature]
  """

  import Kernel, except: [def: 2]
  alias Features.Ast.Compile
  alias Features.Ast.Runtime

  @test Application.compile_env!(:features, :test)

  defmacro __using__(_) do
    quote do
      import Kernel, except: [def: 2]

      Module.register_attribute(__MODULE__, :feature, persist: true)
      Module.register_attribute(__MODULE__, :feature_off, persist: true)

      @features Application.compile_env!(:features, :features)
      @test Application.compile_env!(:features, :test)
      @before_compile Features

      Attributes.set(__MODULE__, [:methods], %{})

      require Features
      import Features
    end
  end

  @doc false
  defmacro def(call, expr) do
    {method, params} =
      case call do
        {:when, _, [{method, _, params} | _]} -> {method, params}
        {method, _, params} -> {method, params}
      end

    param_len = if is_nil(params), do: 0, else: length(params)

    quote do
      feature = Module.get_attribute(__MODULE__, :feature)
      feature_off = Module.get_attribute(__MODULE__, :feature_off)

      if feature != nil && feature_off != nil do
        raise "Cannot use feature and feature_off"
      end

      Attributes.update(
        __MODULE__,
        [:methods, {__MODULE__, unquote(method), unquote(param_len)}],
        [],
        &(&1 ++ [{feature, feature_off, unquote(Macro.escape(call)), unquote(Macro.escape(expr))}])
      )

      Module.delete_attribute(__MODULE__, :feature)
      Module.delete_attribute(__MODULE__, :feature_off)
    end
  end

  defmacro __before_compile__(_) do
    __CALLER__.module
    |> Attributes.get([:methods])
    |> Enum.map(&replace_all/1)
  end

  defp replace_all(methods) do
    if @test, do: Runtime.replace_methods(methods), else: Compile.replace_all(methods)
  end
end
