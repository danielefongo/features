defmodule Features.Ast.Runtime do
  def replace_all({{module, method, arity}, bodies}) do
    params =
      case arity do
        0 -> []
        _ -> Enum.map(1..arity, &{String.to_atom("param_#{&1}"), [], module})
      end

    new_bodies = bodies |> Enum.map(&replace/1) |> List.flatten()

    assignments =
      bodies
      |> Enum.map(fn {feature, feature_off, _, _} ->
        cond do
          feature != nil ->
            quote do
              unquote({feature, [], Elixir}) = Features.Test.enabled?(unquote(feature))
            end

          feature_off != nil ->
            quote do
              unquote({feature_off, [], Elixir}) = Features.Test.enabled?(unquote(feature_off))
            end

          true ->
            nil
        end
      end)
      |> Enum.uniq()

    choices =
      quote do
        case unquote(params) do
          unquote(new_bodies)
        end
      end

    body =
      quote do
        unquote({:__block__, [], assignments ++ [choices]})
      end

    call = {method, [], params}
    expr = [do: body]

    quote do
      Kernel.def(unquote(call), unquote(expr))
    end
  end

  def replace({feature, feature_off, {:when, _, [{_, _, params}, whn]}, [do: body]}) do
    body = replace_body(body)
    params = if is_nil(params), do: [], else: params

    cond do
      feature != nil && feature_off == nil ->
        quote do:
                (unquote(params) when unquote({feature, [], Elixir}) == true and unquote(whn) ->
                   unquote(body))

      feature == nil && feature_off != nil ->
        quote do:
                (unquote(params)
                 when unquote({feature_off, [], Elixir}) == false and unquote(whn) ->
                   unquote(body))

      true ->
        quote do: (unquote(params) and unquote(whn) -> unquote(body))
    end
  end

  def replace({feature, feature_off, {_, _, params}, [do: body]}) do
    body = replace_body(body)
    params = if is_nil(params), do: [], else: params

    cond do
      feature != nil && feature_off == nil ->
        quote do:
                (unquote(params) when unquote({feature, [], Elixir}) == true ->
                   unquote(body))

      feature == nil && feature_off != nil ->
        quote do:
                (unquote(params) when unquote({feature_off, [], Elixir}) == false ->
                   unquote(body))

      true ->
        quote do: (unquote(params) -> unquote(body))
    end
  end

  def replace_body(a) do
    Macro.prewalk(a, fn node ->
      case node do
        {a, b, list} when is_list(list) ->
          {a, b, replace_instructions(list)}

        node ->
          node
      end
    end)
  end

  defp replace_instructions([{:@, _, [{:feature_off, _, [_]}]} = feature, post | tail]),
    do: to_condition([feature, post] ++ tail)

  defp replace_instructions([{:@, _, [{:feature, _, [_]}]} = feature, post | tail]),
    do: to_condition([feature, post] ++ tail)

  defp replace_instructions([pre, {:@, _, [{:feature_off, _, [_]}]} = feature, post | tail]),
    do: to_condition([feature, post] ++ tail, pre)

  defp replace_instructions([pre, {:@, _, [{:feature, _, [_]}]} = feature, post | tail]),
    do: to_condition([feature, post] ++ tail, pre)

  defp replace_instructions(other), do: other

  defp to_condition(instructions, pre \\ nil) do
    blocks =
      instructions
      |> Enum.chunk_every(2, 2, :discard)
      |> Enum.reduce_while([], fn [a, b], l ->
        case [a, b] do
          [{:@, _, [{:feature, _, [_]}]} = feature, _] -> {:cont, l ++ [{true, feature, b}]}
          [{:@, _, [{:feature_off, _, [_]}]} = feature, _] -> {:cont, l ++ [{false, feature, b}]}
          [_, {:feature, _, [_feature]}] -> {:halt, l}
          _ -> {:halt, l}
        end
      end)
      |> Enum.map(fn {enabled, {:@, _, [{_, _, [feature]}]}, code} ->
        case pre do
          nil ->
            quote do
              Features.Test.enabled?(unquote(feature)) == unquote(enabled) -> unquote(code)
            end

          _ ->
            quote do
              Features.Test.enabled?(unquote(feature)) == unquote(enabled) ->
                unquote(pre)
                unquote(code)
            end
        end
      end)
      |> List.flatten()

    tail = Enum.drop(instructions, length(blocks) * 2)

    blocks =
      blocks ++
        quote do
          true -> unquote(pre)
        end

    [
      quote do
        cond do
          unquote(blocks)
        end
      end
    ] ++ replace_instructions(tail)
  end
end
