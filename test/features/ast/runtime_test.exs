defmodule Features.Ast.RuntimeTest do
  use ExUnit.Case, async: true
  require Features.Ast.Runtime
  alias Features.Ast.Runtime

  describe "replace_body" do
    test "0 instructions without features" do
      body =
        quote do
        end

      assert_same_macro(Runtime.replace_body(body), body)
    end

    test "1 instruction without features" do
      body =
        quote do
          :first
        end

      assert_same_macro(Runtime.replace_body(body), body)
    end

    test "2 instructions without features" do
      body =
        quote do
          :first
          :second
        end

      assert_same_macro(Runtime.replace_body(body), body)
    end

    test "feature on between instructions" do
      body =
        quote do
          :first
          @feature :feature
          :second
        end

      expected =
        quote do
          cond do
            Features.Test.enabled?(:feature) == true ->
              :first
              :second

            true ->
              :first
          end
        end

      assert_same_macro(Runtime.replace_body(body), expected)
    end

    test "feature off between instructions" do
      body =
        quote do
          :first
          @feature_off :feature
          :second
        end

      expected =
        quote do
          cond do
            Features.Test.enabled?(:feature) == false ->
              :first
              :second

            true ->
              :first
          end
        end

      assert_same_macro(Runtime.replace_body(body), expected)
    end

    test "feature on between instructions with following instructions" do
      body =
        quote do
          :first
          @feature :feature
          :second
          :other
        end

      expected =
        quote do
          cond do
            Features.Test.enabled?(:feature) == true ->
              :first
              :second

            true ->
              :first
          end

          :other
        end

      assert_same_macro(Runtime.replace_body(body), expected)
    end

    test "feature on before instruction" do
      body =
        quote do
          @feature :feature
          :something
        end

      expected =
        quote do
          cond do
            Features.Test.enabled?(:feature) == true -> :something
            true -> nil
          end
        end

      assert_same_macro(Runtime.replace_body(body), expected)
    end

    test "feature off before instruction" do
      body =
        quote do
          @feature_off :feature
          :something
        end

      expected =
        quote do
          cond do
            Features.Test.enabled?(:feature) == false -> :something
            true -> nil
          end
        end

      assert_same_macro(Runtime.replace_body(body), expected)
    end

    test "feature on before instruction with following instructions" do
      body =
        quote do
          @feature :feature
          :something
          :return
        end

      expected =
        quote do
          cond do
            Features.Test.enabled?(:feature) == true -> :something
            true -> nil
          end

          :return
        end

      assert_same_macro(Runtime.replace_body(body), expected)
    end

    test "multiple features on" do
      body =
        quote do
          @feature :feature1
          :first
          @feature :feature2
          :second
          @feature :feature3
          :third
        end

      expected =
        quote do
          cond do
            Features.Test.enabled?(:feature1) == true -> :first
            Features.Test.enabled?(:feature2) == true -> :second
            Features.Test.enabled?(:feature3) == true -> :third
            true -> nil
          end
        end

      assert_same_macro(Runtime.replace_body(body), expected)
    end

    test "multiple features on with following instructions" do
      body =
        quote do
          @feature :feature1
          :first
          @feature :feature2
          :second
          :other
        end

      expected =
        quote do
          cond do
            Features.Test.enabled?(:feature1) == true -> :first
            Features.Test.enabled?(:feature2) == true -> :second
            true -> nil
          end

          :other
        end

      assert_same_macro(Runtime.replace_body(body), expected)
    end

    test "multiple features on and off" do
      body =
        quote do
          @feature :feature1
          :first
          @feature_off :feature2
          :second
          @feature :feature3
          :third
        end

      expected =
        quote do
          cond do
            Features.Test.enabled?(:feature1) == true -> :first
            Features.Test.enabled?(:feature2) == false -> :second
            Features.Test.enabled?(:feature3) == true -> :third
            true -> nil
          end
        end

      assert_same_macro(Runtime.replace_body(body), expected)
    end

    test "feature on inside nested block" do
      body =
        quote do
          if true do
            @feature :feature
            :something
          end
        end

      expected =
        quote do
          if true do
            cond do
              Features.Test.enabled?(:feature) == true -> :something
              true -> nil
            end
          end
        end

      assert_same_macro(Runtime.replace_body(body), expected)
    end

    test "block after feature on" do
      body =
        quote do
          @feature :feature
          if true do
            :something
          end
        end

      expected =
        quote do
          cond do
            Features.Test.enabled?(:feature) == true ->
              if true do
                :something
              end

            true ->
              nil
          end
        end

      assert_same_macro(Runtime.replace_body(body), expected)
    end

    test "featured block after feature on" do
      body =
        quote do
          @feature :feature
          if true do
            @feature :feature2
            :something
          end
        end

      expected =
        quote do
          cond do
            Features.Test.enabled?(:feature) == true ->
              if true do
                cond do
                  Features.Test.enabled?(:feature2) == true -> :something
                  true -> nil
                end
              end

            true ->
              nil
          end
        end

      assert_same_macro(Runtime.replace_body(body), expected)
    end
  end

  describe "replace_method" do
    test "without params" do
      {:def, _, [call, body]} =
        quote do
          def method(), do: :ok
        end

      expected =
        quote do
          [] when true -> :ok
        end

      assert_same_macro(Runtime.replace_method({nil, nil, :any_doc, call, body}), expected)
    end

    test "without features" do
      {:def, _, [call, body]} =
        quote do
          def method(a, b), do: :ok
        end

      expected =
        quote do
          [a, b] when true -> :ok
        end

      assert_same_macro(Runtime.replace_method({nil, nil, :any_doc, call, body}), expected)
    end

    test "with pattern matching" do
      {:def, _, [call, body]} =
        quote do
          def method(a, %{a: b} = c), do: :ok
        end

      expected =
        quote do
          [a, %{a: b} = c] when true -> :ok
        end

      assert_same_macro(Runtime.replace_method({nil, nil, :any_doc, call, body}), expected)
    end

    test "with feature on" do
      {:def, _, [call, body]} =
        quote do
          def method(a, b), do: :ok
        end

      expected =
        quote do
          [a, b] when feature == true and true -> :ok
        end

      assert_same_macro(Runtime.replace_method({:feature, nil, :any_doc, call, body}), expected)
    end

    test "with feature off" do
      {:def, _, [call, body]} =
        quote do
          def method(a, b), do: :ok
        end

      expected =
        quote do
          [a, b] when feature_off == false and true -> :ok
        end

      assert_same_macro(
        Runtime.replace_method({nil, :feature_off, :any_doc, call, body}),
        expected
      )
    end

    test "with feature on and complex body" do
      {:def, _, [call, body]} =
        quote do
          def method(a, b) do
            @feature :feature
            :ok
          end
        end

      expected =
        quote do
          [a, b] when feature == true and true ->
            cond do
              Features.Test.enabled?(:feature) == true -> :ok
              true -> nil
            end
        end

      assert_same_macro(Runtime.replace_method({:feature, nil, :any_doc, call, body}), expected)
    end

    test "with when and feature on" do
      {:def, _, [call, body]} =
        quote do
          def method(a, b) when a == 1, do: :ok
        end

      expected =
        quote do
          [a, b] when feature == true and a == 1 -> :ok
        end

      assert_same_macro(Runtime.replace_method({:feature, nil, :any_doc, call, body}), expected)
    end

    test "with defaults and feature on" do
      {:def, _, [call, body]} =
        quote do
          def method(a, b \\ nil), do: :ok
        end

      expected =
        quote do
          [a, b] when feature == true and true -> :ok
        end

      assert_same_macro(Runtime.replace_method({:feature, nil, :any_doc, call, body}), expected)
    end

    test "with when and feature off" do
      {:def, _, [call, body]} =
        quote do
          def method(a, b) when a == 1, do: :ok
        end

      expected =
        quote do
          [a, b] when feature_off == false and a == 1 -> :ok
        end

      assert_same_macro(
        Runtime.replace_method({nil, :feature_off, :any_doc, call, body}),
        expected
      )
    end

    test "with multiple when" do
      {:def, _, [call, body]} =
        quote do
          def method(a, b) when a == 1 or a != 2, do: :ok
        end

      expected =
        quote do
          [a, b] when feature == true and (a == 1 or a != 2) -> :ok
        end

      assert_same_macro(Runtime.replace_method({:feature, nil, :any_doc, call, body}), expected)
    end

    test "with defaults" do
      {:def, _, [call, body]} =
        quote do
          def method(a, b \\ nil), do: :ok
        end

      expected =
        quote do
          [a, b] when feature == true and true -> :ok
        end

      assert_same_macro(Runtime.replace_method({:feature, nil, :any_doc, call, body}), expected)
    end
  end

  describe "replace_methods" do
    test "methods only" do
      {:def, _, [call1, body1]} =
        quote do
          def method(1, b) when b == 1, do: :ok
        end

      {:def, _, [call2, body2]} =
        quote do
          def method(2, b) when b == 2, do: :ok
        end

      {:def, _, [call3, body3]} =
        quote do
          def method(3, b) when b == 3, do: :ok
        end

      expected =
        quote do
          Kernel.def method(param_1, param_2) do
            feature = Features.Test.enabled?(:feature)
            not_enabled_feature = Features.Test.enabled?(:not_enabled_feature)

            case [param_1, param_2] do
              [1, b] when feature == true and b == 1 -> :ok
              [2, b] when feature == true and b == 2 -> :ok
              [3, b] when not_enabled_feature == false and b == 3 -> :ok
            end
          end
        end

      generated =
        Runtime.replace_methods(
          {{MyModule, :method, 2},
           [
             {:feature, nil, :any_doc, call1, body1},
             {:feature, nil, :any_doc, call2, body2},
             {nil, :not_enabled_feature, :any_doc, call3, body3}
           ]}
        )

      assert_same_macro(generated, expected)
    end

    test "header only" do
      {:def, _, [call1]} =
        quote do
          def method(a, b \\ nil)
        end

      expected =
        quote do
          Kernel.def method(param_1, param_2 \\ nil) do
            nil
          end
        end

      generated =
        Runtime.replace_methods({{MyModule, :method, 2}, [{:any, :any, :any_doc, call1, nil}]})

      assert_same_macro(generated, expected)
    end

    test "header and methods" do
      {:def, _, [call1]} =
        quote do
          def method(a, b \\ nil)
        end

      {:def, _, [call2, body2]} =
        quote do
          def method(1, b) when b == 1, do: :ok
        end

      expected =
        quote do
          Kernel.def method(param_1, param_2 \\ nil) do
            feature = Features.Test.enabled?(:feature)

            case [param_1, param_2] do
              [1, b] when feature == true and b == 1 -> :ok
            end
          end
        end

      generated =
        Runtime.replace_methods(
          {{MyModule, :method, 2},
           [
             {:any, :any, :any_doc, call1, nil},
             {:feature, nil, :any_doc, call2, body2}
           ]}
        )

      assert_same_macro(generated, expected)
    end
  end

  defp assert_same_macro(macro1, macro2) do
    assert Macro.to_string(macro1) == Macro.to_string(macro2)
  end
end
