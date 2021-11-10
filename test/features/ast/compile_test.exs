defmodule Features.Ast.CompileTest do
  use ExUnit.Case, async: true
  require Features.Ast.Compile
  alias Features.Ast.Compile

  describe "replace_body" do
    test "0 instructions without features" do
      body =
        quote do
        end

      assert_same_macro(Compile.replace_body(body), body)
    end

    test "1 instruction without features" do
      body =
        quote do
          :first
        end

      assert_same_macro(Compile.replace_body(body), body)
    end

    test "2 instructions without features" do
      body =
        quote do
          :first
          :second
        end

      assert_same_macro(Compile.replace_body(body), body)
    end

    test "feature on for enabled one" do
      body =
        quote do
          @feature :enabled_feature
          :ok
        end

      expected =
        quote do
          :ok
        end

      assert_same_macro(Compile.replace_body(body), expected)
    end

    test "feature off for enabled one" do
      body =
        quote do
          @feature_off :enabled_feature
          :ok
        end

      expected =
        quote do
        end

      assert_same_macro(Compile.replace_body(body), expected)
    end

    test "feature on for not_enabled one" do
      body =
        quote do
          @feature :not_enabled_feature
          :ok
        end

      expected =
        quote do
        end

      assert_same_macro(Compile.replace_body(body), expected)
    end

    test "feature off for not_enabled" do
      body =
        quote do
          @feature_off :not_enabled_feature
          :ok
        end

      expected =
        quote do
          :ok
        end

      assert_same_macro(Compile.replace_body(body), expected)
    end

    test "feature on between instructions" do
      body =
        quote do
          :first
          @feature :enabled_feature
          :second
          :other
        end

      expected =
        quote do
          :first
          :second
          :other
        end

      assert_same_macro(Compile.replace_body(body), expected)
    end

    test "multiple features on" do
      body =
        quote do
          @feature :enabled_feature
          :first
          @feature :enabled_feature
          :second
          @feature :enabled_feature
          :third
        end

      expected =
        quote do
          :first
          :second
          :third
        end

      assert_same_macro(Compile.replace_body(body), expected)
    end

    test "multiple features on between instructions" do
      body =
        quote do
          :ok
          @feature :enabled_feature
          :first
          @feature :enabled_feature
          :second
          :ok2
        end

      expected =
        quote do
          :ok
          :first
          :second
          :ok2
        end

      assert_same_macro(Compile.replace_body(body), expected)
    end

    test "multiple features on and off" do
      body =
        quote do
          @feature :enabled_feature
          :first
          @feature_off :not_enabled_feature
          :second
          @feature :not_enabled_feature
          :third
        end

      expected =
        quote do
          :first
          :second
        end

      assert_same_macro(Compile.replace_body(body), expected)
    end

    test "feature on inside nested block" do
      body =
        quote do
          if true do
            if true do
              @feature :enabled_feature
              :something
            end
          end
        end

      expected =
        quote do
          if true do
            if true do
              :something
            end
          end
        end

      assert_same_macro(Compile.replace_body(body), expected)
    end

    test "block after feature on" do
      body =
        quote do
          @feature :enabled_feature
          if true do
            :something
          end
        end

      expected =
        quote do
          if true do
            :something
          end
        end

      assert_same_macro(Compile.replace_body(body), expected)
    end

    test "featured block after feature on" do
      body =
        quote do
          @feature :enabled_feature
          if true do
            @feature :enabled_feature
            :something
          end
        end

      expected =
        quote do
          if true do
            :something
          end
        end

      assert_same_macro(Compile.replace_body(body), expected)
    end
  end

  describe "replace" do
    test "without features" do
      {:def, _, [call, body]} =
        quote do
          def method(a, b), do: :ok
        end

      expected =
        quote do
          Kernel.def(method(a, b), do: :ok)
        end

      assert_same_macro(Compile.replace_method({nil, nil, call, body}), expected)
    end

    test "feature on for enabled one" do
      {:def, _, [call, body]} =
        quote do
          def method(a, b), do: :ok
        end

      expected =
        quote do
          Kernel.def(method(a, b), do: :ok)
        end

      assert_same_macro(Compile.replace_method({:enabled_feature, nil, call, body}), expected)
    end

    test "feature off for enabled one" do
      {:def, _, [call, body]} =
        quote do
          def method(a, b), do: :ok
        end

      expected =
        quote do
          nil
        end

      assert_same_macro(Compile.replace_method({nil, :enabled_feature, call, body}), expected)
    end

    test "feature off for disabled one" do
      {:def, _, [call, body]} =
        quote do
          def method(a, b), do: :ok
        end

      expected =
        quote do
          Kernel.def(method(a, b), do: :ok)
        end

      assert_same_macro(Compile.replace_method({nil, :not_enabled_feature, call, body}), expected)
    end

    test "feature on for disabled one" do
      {:def, _, [call, body]} =
        quote do
          def method(a, b), do: :ok
        end

      expected =
        quote do
          nil
        end

      assert_same_macro(Compile.replace_method({:not_enabled_feature, nil, call, body}), expected)
    end

    test "feature on and complex body" do
      {:def, _, [call, body]} =
        quote do
          def method(a, b) do
            @feature :enabled_feature
            :enabled_feature
            @feature :not_enabled_feature
            :not_enabled_feature
          end
        end

      expected =
        quote do
          Kernel.def method(a, b) do
            :enabled_feature
          end
        end

      assert_same_macro(Compile.replace_method({:enabled_feature, nil, call, body}), expected)
    end

    test "when and feature on" do
      {:def, _, [call, body]} =
        quote do
          def method(a, b) when a == 1, do: :ok
        end

      expected =
        quote do
          Kernel.def method(a, b) when a == 1 do
            :ok
          end
        end

      assert_same_macro(Compile.replace_method({:enabled_feature, nil, call, body}), expected)
    end

    test "when and feature off" do
      {:def, _, [call, body]} =
        quote do
          def method(a, b) when a == 1, do: :ok
        end

      expected =
        quote do
          Kernel.def method(a, b) when a == 1 do
            :ok
          end
        end

      assert_same_macro(Compile.replace_method({nil, :not_enabled_feature, call, body}), expected)
    end

    test "header and feature on" do
      {:def, _, [call]} =
        quote do
          def method(a, b \\ nil)
        end

      expected =
        quote do
          Kernel.def(method(a, b \\ nil), nil)
        end

      assert_same_macro(Compile.replace_method({:enabled_feature, nil, call, nil}), expected)
    end

    test "header and feature off" do
      {:def, _, [call]} =
        quote do
          def method(a, b \\ nil)
        end

      expected =
        quote do
          Kernel.def(method(a, b \\ nil), nil)
        end

      assert_same_macro(Compile.replace_method({nil, :not_enabled_feature, call, nil}), expected)
    end

    test "with defaults" do
      {:def, _, [call, body]} =
        quote do
          def method(a, b \\ nil), do: :ok
        end

      expected =
        quote do
          Kernel.def method(a, b \\ nil) do
            :ok
          end
        end

      assert_same_macro(Compile.replace_method({:enabled_feature, nil, call, body}), expected)
    end
  end

  test "replace_all" do
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
        Kernel.def(method(1, b) when b == 1, do: :ok)
        Kernel.def(method(3, b) when b == 3, do: :ok)
      end

    generated =
      Compile.replace_all(
        {{MyModule, :method, 2},
         [
           {:enabled_feature, nil, call1, body1},
           {:not_enabled_feature, nil, call2, body2},
           {nil, nil, call3, body3}
         ]}
      )

    assert_same_macro(generated, expected)
  end

  defp assert_same_macro(macro1, macro2) do
    assert Macro.to_string(macro1) == Macro.to_string(macro2)
  end
end
