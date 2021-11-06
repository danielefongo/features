defmodule Features do
  @moduledoc false

  require Features.Ast.Runtime
  import Kernel, except: [def: 2]
  import Enum, only: [filter: 2]
  alias Features.Ast.Runtime

  @features Application.compile_env!(:features, :features)
  @test Application.compile_env!(:features, :test)
  @trash :__features_trash_stuff

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

  defmacro def(call, expr) when @test == false do
    {_, expr} = Keyword.get_and_update(expr, :do, fn body -> {body, update_body(body)} end)

    quote do
      feature = Module.get_attribute(__MODULE__, :feature)
      feature_off = Module.get_attribute(__MODULE__, :feature_off)

      cond do
        feature != nil && feature_off != nil ->
          raise "Cannot use feature and feature_off"

        feature != nil ->
          if feature in @features do
            Kernel.def(unquote(call), unquote(expr))
          end

        feature_off != nil ->
          if feature_off not in @features do
            Kernel.def(unquote(call), unquote(expr))
          end

        true ->
          Kernel.def(unquote(call), unquote(expr))
      end

      Module.delete_attribute(__MODULE__, :feature)
      Module.delete_attribute(__MODULE__, :feature_off)
    end
  end

  defmacro def(call, expr) when @test == true do
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
    |> Enum.map(&Runtime.replace_all/1)
  end

  defp update_body(body),
    do:
      body
      |> Macro.traverse(nil, &pre/2, &post/2)
      |> elem(0)

  defp pre({:@, _, [{:feature, _, [feature]}]}, nil), do: {@trash, {:on, feature}}
  defp pre({:@, _, [{:feature_off, _, [feature]}]}, nil), do: {@trash, {:off, feature}}
  defp pre(node, {:on, feature}), do: {if(feature in @features, do: node, else: @trash), nil}
  defp pre(node, {:off, feature}), do: {if(feature not in @features, do: node, else: @trash), nil}
  defp pre(node, _), do: {node, nil}

  defp post({:__block__, _, block}, a), do: {{:__block__, [], filter(block, &(&1 != @trash))}, a}
  defp post(node, a), do: {node, a}
end
