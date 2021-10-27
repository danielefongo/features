defmodule Features do
  @moduledoc false

  import Kernel, except: [def: 2]
  @enabled_features Application.compile_env!(:features, :features)
  @trash_stuff_tag :__features_trash_stuff

  defmacro __using__(_) do
    quote do
      import Kernel, except: [def: 2]

      @enabled_features Application.compile_env!(:features, :features)

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

  Kernel.def update_body(body) do
    body
    |> Macro.prewalk(nil, fn node, acc ->
      case {node, acc} do
        {{:@, _, [{:feature, _, [feature]}]}, nil} ->
          {@trash_stuff_tag, {:has, feature}}

        {{:@, _, [{:feature_off, _, [feature]}]}, nil} ->
          {@trash_stuff_tag, {:has_no, feature}}

        {node, {:has, feature}} ->
          {if(feature in @enabled_features, do: node, else: @trash_stuff_tag), nil}

        {node, {:has_no, feature}} ->
          {if(feature not in @enabled_features, do: node, else: @trash_stuff_tag), nil}

        _ ->
          {node, nil}
      end
    end)
    |> elem(0)
    |> Macro.postwalk(fn node ->
      case node do
        {:__block__, _, block} -> {:__block__, [], Enum.filter(block, &(&1 != @trash_stuff_tag))}
        node -> node
      end
    end)
  end
end
