defmodule FeaturesTest do
  use ExUnit.Case
  use Features

  describe "simple macro" do
    test "check enabled feature" do
      assert true ==
               (feature :enabled_feature do
                  true
                end)
    end

    test "check not enabled feature" do
      assert true ==
               (no_feature :not_enabled_feature do
                  true
                end)
    end

    test "not enabled feature generate nil code" do
      assert nil ==
               (feature :not_enabled_feature do
                  :should_not_return_this
                end)
    end
  end

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

    test "feature on for undefined feature" do
      defmodule FunctionFeatureOnForUndefniedFeature do
        use Features

        @feature :not_enabled_feature
        def hello, do: :hello
      end

      assert_raise UndefinedFunctionError, fn -> FunctionFeatureOnForUndefniedFeature.hello() end
    end

    test "feature off for defined feature" do
      defmodule FunctionFeatureOffForDefinedFeature do
        use Features

        @feature_off :enabled_feature
        def hello, do: :hello
      end

      assert_raise UndefinedFunctionError, fn -> FunctionFeatureOffForDefinedFeature.hello() end
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
    test "feature on" do
      defmodule BlockFeatureOn do
        use Features

        def hello do
          @feature :enabled_feature
          :ok
        end
      end

      assert BlockFeatureOn.hello() == :ok
    end

    test "feature off" do
      defmodule BlockFeatureOff do
        use Features

        def hello do
          @feature_off :not_enabled_feature
          :ok
        end
      end

      assert BlockFeatureOff.hello() == :ok
    end

    test "feature on not defined" do
      defmodule BlockFeatureOnNotDefined do
        use Features

        def hello do
          @feature :not_enabled_feature
          :ok
        end
      end

      assert BlockFeatureOnNotDefined.hello() == nil
    end

    test "feature off defined" do
      defmodule BlockFeatureOffDefined do
        use Features

        def hello do
          @feature_off :enabled_feature
          :ok
        end
      end

      assert BlockFeatureOffDefined.hello() == nil
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
