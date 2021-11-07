defmodule Features.Ast.Runtime do
  @moduledoc false

  def replace_methods({{module, method, arity}, methods}) do
    params = wrapper_params(module, arity)
    assignments = methods |> Enum.map(&wrapper_assignment/1) |> Enum.uniq()
    clauses = methods |> Enum.map(&replace_method/1) |> List.flatten()
    condition = wrapper_condition(params, clauses)

    call = {method, [], params}
    expr = [do: {:__block__, [], assignments ++ [condition]}]

    quote do
      Kernel.def(unquote(call), unquote(expr))
    end
  end

  def replace_method({feature, feature_off, {:when, _, [{_, _, params}, whn]}, [do: body]}) do
    params = method_params(params)
    body = replace_body(body)

    method_clause(feature, feature_off, params, whn, body)
  end

  def replace_method({feature, feature_off, {_, _, params}, [do: body]}) do
    params = method_params(params)
    body = replace_body(body)

    method_clause(feature, feature_off, params, true, body)
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
    do: block_condition([feature, post] ++ tail)

  defp replace_instructions([{:@, _, [{:feature, _, [_]}]} = feature, post | tail]),
    do: block_condition([feature, post] ++ tail)

  defp replace_instructions([pre, {:@, _, [{:feature_off, _, [_]}]} = feature, post | tail]),
    do: block_condition([feature, post] ++ tail, pre)

  defp replace_instructions([pre, {:@, _, [{:feature, _, [_]}]} = feature, post | tail]),
    do: block_condition([feature, post] ++ tail, pre)

  defp replace_instructions(other), do: other

  # Params

  defp wrapper_params(_module, 0), do: []

  defp wrapper_params(module, arity),
    do: Enum.map(1..arity, &{String.to_atom("param_#{&1}"), [], module})

  def method_params(nil), do: []
  def method_params(params), do: params

  # Assignments

  defp wrapper_assignment({nil, nil, _, _}), do: nil

  defp wrapper_assignment({feature, nil, _, _}) do
    quote do
      unquote({feature, [], Elixir}) = Features.Test.enabled?(unquote(feature))
    end
  end

  defp wrapper_assignment({nil, feature_off, _, _}) do
    quote do
      unquote({feature_off, [], Elixir}) = Features.Test.enabled?(unquote(feature_off))
    end
  end

  # Conditions and cases

  def wrapper_condition(params, methods) do
    quote do
      case unquote(params), do: unquote(methods)
    end
  end

  defp block_condition(instructions, pre \\ nil) do
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
      |> Enum.map(&block_clause(pre, &1))
      |> List.flatten()

    tail = Enum.drop(instructions, length(blocks) * 2)
    blocks = blocks ++ quote do: (true -> unquote(pre))

    [quote(do: cond(do: unquote(blocks)))] ++ replace_instructions(tail)
  end

  # Clauses

  def method_clause(nil, nil, params, whn, body) do
    quote do
      unquote(params) when unquote(whn) -> unquote(body)
    end
  end

  def method_clause(feature, nil, params, whn, body) do
    feature = {feature, [], Elixir}

    quote do
      unquote(params) when unquote(feature) == true and unquote(whn) -> unquote(body)
    end
  end

  def method_clause(nil, feature_off, params, whn, body) do
    feature_off = {feature_off, [], Elixir}

    quote do
      unquote(params) when unquote(feature_off) == false and unquote(whn) -> unquote(body)
    end
  end

  defp block_clause(nil, {enabled, {:@, _, [{_, _, [feature]}]}, code}) do
    quote do
      Features.Test.enabled?(unquote(feature)) == unquote(enabled) -> unquote(code)
    end
  end

  defp block_clause(pre, {enabled, {:@, _, [{_, _, [feature]}]}, code}) do
    quote do
      Features.Test.enabled?(unquote(feature)) == unquote(enabled) ->
        unquote(pre)
        unquote(code)
    end
  end
end
