defmodule Features do
  @moduledoc false

  import Kernel, except: [def: 2]
  import Enum, only: [filter: 2]
  @features Application.compile_env!(:features, :features)
  @trash :__features_trash_stuff

  defmacro __using__(_) do
    quote do
      import Kernel, except: [def: 2]

      @features Application.compile_env!(:features, :features)

      require Features
      import Features
    end
  end

  defmacro def(call, expr) do
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
