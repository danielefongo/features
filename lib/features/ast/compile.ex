defmodule Features.Ast.Compile do
  @moduledoc false

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

  def replace_method({nil, nil, doc, call, expr}) do
    quote do
      @doc unquote(get_doc(doc))
      Kernel.def(unquote(call), unquote(replace_body(expr)))
    end
  end

  def replace_method({nil, feature_off, doc, call, expr}) do
    if feature_off not in fts() do
      quote do
        @doc unquote(get_doc(doc))
        Kernel.def(unquote(call), unquote(replace_body(expr)))
      end
    end
  end

  def replace_method({feature, nil, doc, call, expr}) do
    if feature in fts() do
      quote do
        @doc unquote(get_doc(doc))
        Kernel.def(unquote(call), unquote(replace_body(expr)))
      end
    end
  end

  def replace_method({_, _, _, _, _}), do: raise("Cannot use feature and feature_off")

  defp get_doc({_, doc}), do: doc
  defp get_doc(nil), do: nil

  def replace_body(body),
    do:
      body
      |> Macro.traverse(nil, &pre/2, &post/2)
      |> elem(0)

  defp pre({:@, _, [{:feature, _, [feature]}]}, nil), do: {@trash, {:on, feature}}
  defp pre({:@, _, [{:feature_off, _, [feature]}]}, nil), do: {@trash, {:off, feature}}
  defp pre(node, {:on, feature}), do: {if(feature in fts(), do: node, else: @trash), nil}
  defp pre(node, {:off, feature}), do: {if(feature not in fts(), do: node, else: @trash), nil}
  defp pre(node, _), do: {node, nil}

  defp post({:__block__, _, block}, a), do: {{:__block__, [], filter(block, &(&1 != @trash))}, a}
  defp post(node, a), do: {node, a}

  defp fts, do: Application.fetch_env!(:features, :features)
end
