defmodule FeaturesTest do
  use ExUnit.Case
  use Features

  describe "function annotation" do
    test "feature on" do
      defmodule FunctionFeatureOn do
        use Features

        @feature :enabled_feature
        def hello, do: :hello
      end

      assert FunctionFeatureOn.hello() == :hello
    end

    test "feature off" do
      defmodule FunctionFeatureOff do
        use Features

        @feature_off :not_enabled_feature
        def hello, do: :hello
      end

      assert FunctionFeatureOff.hello() == :hello
    end

    test "feature on for not enabled feature" do
      defmodule FunctionFeatureOnForNotEnabledFeature do
        use Features

        @feature :not_enabled_feature
        def hello, do: :hello
      end

      assert_raise UndefinedFunctionError, fn -> FunctionFeatureOnForNotEnabledFeature.hello() end
    end

    test "feature off for enabled feature" do
      defmodule FunctionFeatureOffForEnabledFeature do
        use Features

        @feature_off :enabled_feature
        def hello, do: :hello
      end

      assert_raise UndefinedFunctionError, fn -> FunctionFeatureOffForEnabledFeature.hello() end
    end

    test "feature off not propagated" do
      defmodule FunctionFeatureOffNotPropagated do
        use Features

        @feature_off :enabled_feature
        def hello, do: :hello

        def present?, do: true
      end

      assert FunctionFeatureOffNotPropagated.present?() == true
    end
  end

  describe "block annotation" do
    test "feature on for enabled feature" do
      defmodule BlockFeatureOnForEnabledFeature do
        use Features

        def hello do
          @feature :enabled_feature
          :ok
        end
      end

      assert BlockFeatureOnForEnabledFeature.hello() == :ok
    end

    test "feature off for not enabled feature" do
      defmodule BlockFeatureOffForNotEnabledFeature do
        use Features

        def hello do
          @feature_off :not_enabled_feature
          :ok
        end
      end

      assert BlockFeatureOffForNotEnabledFeature.hello() == :ok
    end

    test "feature on for not enabled feature" do
      defmodule BlockFeatureOnForNotEnabledFeature do
        use Features

        def hello do
          @feature :not_enabled_feature
          :ok
        end
      end

      assert BlockFeatureOnForNotEnabledFeature.hello() == nil
    end

    test "feature off for enabled feature" do
      defmodule BlockFeatureOffForEnabledFeature do
        use Features

        def hello do
          @feature_off :enabled_feature
          :ok
        end
      end

      assert BlockFeatureOffForEnabledFeature.hello() == nil
    end

    test "nested annotation" do
      defmodule BlockNestedAnnotation do
        use Features

        def hello do
          if true do
            if true do
              if true do
                @feature :enabled_feature
                :ok
              end
            end
          end
        end
      end

      assert BlockNestedAnnotation.hello() == :ok
    end

    test "annotation for deep block" do
      defmodule BlockAnnotationForDeepBlock do
        use Features

        def hello do
          @feature :enabled_feature
          if true do
            if true do
              if true do
                :ok
              end
            end
          end
        end
      end

      assert BlockAnnotationForDeepBlock.hello() == :ok
    end

    test "feature off and feature on" do
      defmodule BlockFeatureOffFeatureOn do
        use Features

        def hello do
          @feature_off :enabled_feature
          :off
          @feature :enabled_feature
          :on
        end
      end

      assert BlockFeatureOffFeatureOn.hello() == :on
    end

    test "override first statement" do
      defmodule BlockOverrideFirstStatement do
        use Features

        def hello do
          @feature :enabled_feature
          :something

          :ok
        end
      end

      assert BlockOverrideFirstStatement.hello() == :ok
    end
  end
end
