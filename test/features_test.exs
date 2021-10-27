defmodule FeaturesTest do
  use ExUnit.Case
  use Features

  describe "simple macro" do
    test "check enabled feature" do
      assert true ==
               (feature :feature_x do
                  true
                end)
    end

    test "check not enabled feature" do
      assert true ==
               (no_feature :feature_y do
                  true
                end)
    end

    test "not enabled feature generate nil code" do
      assert nil ==
               (feature :feature_y do
                  :should_not_return_this
                end)
    end
  end

  describe "function annotation" do
    test "feature on" do
      defmodule FunctionFeatureOn do
        use Features

        @feature :feature_x
        def hello, do: :hello
      end

      assert FunctionFeatureOn.hello() == :hello
    end

    test "feature off" do
      defmodule FunctionFeatureOff do
        use Features

        @feature_off :feature_y
        def hello, do: :hello
      end

      assert FunctionFeatureOff.hello() == :hello
    end

    test "feature on for undefined feature" do
      defmodule FunctionFeatureOnForUndefniedFeature do
        use Features

        @feature :feature_y
        def hello, do: :hello
      end

      assert_raise UndefinedFunctionError, fn -> FunctionFeatureOnForUndefniedFeature.hello() end
    end

    test "feature off for defined feature" do
      defmodule FunctionFeatureOffForDefinedFeature do
        use Features

        @feature_off :feature_x
        def hello, do: :hello
      end

      assert_raise UndefinedFunctionError, fn -> FunctionFeatureOffForDefinedFeature.hello() end
    end

    test "feature off not propagated" do
      defmodule FunctionFeatureOffNotPropagated do
        use Features

        @feature_off :feature_x
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
          @feature :feature_x
          :ok
        end
      end

      assert BlockFeatureOn.hello() == :ok
    end

    test "feature off" do
      defmodule BlockFeatureOff do
        use Features

        def hello do
          @feature_off :feature_y
          :ok
        end
      end

      assert BlockFeatureOff.hello() == :ok
    end

    test "feature on not defined" do
      defmodule BlockFeatureOnNotDefined do
        use Features

        def hello do
          @feature :feature_y
          :ok
        end
      end

      assert BlockFeatureOnNotDefined.hello() == nil
    end

    test "feature off defined" do
      defmodule BlockFeatureOffDefined do
        use Features

        def hello do
          @feature_off :feature_x
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
                @feature :feature_x
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
          @feature :feature_x
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
          @feature_off :feature_x
          :off
          @feature :feature_x
          :on
        end
      end

      assert BlockFeatureOffFeatureOn.hello() == :on
    end

    test "override first statement" do
      defmodule BlockOverrideFirstStatement do
        use Features

        def hello do
          @feature :feature_x
          :something

          :ok
        end
      end

      assert BlockOverrideFirstStatement.hello() == :ok
    end
  end
end
