defmodule Features.Ast.Compile do
  @moduledoc false

  @features Application.compile_env!(:features, :features)
  @trash :__features_trash_stuff

  import Enum, only: [filter: 2]

  def replace_all({{_, _, _}, bodies}) do
    new_bodies =
      bodies
      |> Enum.map(&replace_method/1)
      |> List.flatten()
      |> Enum.filter(&(not is_nil(&1)))

    {:__block__, [], new_bodies}
  end

  def replace_method({nil, nil, call, [do: body]}) do
    quote do: Kernel.def(unquote(call), do: unquote(replace_body(body)))
  end

  def replace_method({nil, feature_off, call, [do: body]}) do
    if feature_off not in @features do
      quote do: Kernel.def(unquote(call), do: unquote(replace_body(body)))
    end
  end

  def replace_method({feature, nil, call, [do: body]}) do
    if feature in @features do
      quote do: Kernel.def(unquote(call), do: unquote(replace_body(body)))
    end
  end

  def replace_method(_), do: raise("Cannot use feature and feature_off")

  def replace_body(body),
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
