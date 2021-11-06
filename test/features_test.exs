defmodule FeaturesTest do
  use ExUnit.Case
  use Features
  use Features.Test

  defmodule MyModule do
    use Features

    @feature :feature1
    def feature1(a, _b), do: a

    @feature :feature2
    def feature2(a) when a == true, do: :ok

    @feature :feature2
    def feature2(a) when a == false, do: :ko

    def inner_features do
      @feature :feature1
      :feature1
      @feature :feature2
      :feature2
    end
  end

  if not @test do
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

        assert_raise UndefinedFunctionError, fn ->
          FunctionFeatureOnForNotEnabledFeature.hello()
        end
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

      test "feature on for enabled feature with complex data" do
        defmodule BlockFeatureOnForEnabledFeatureWithComplexData do
          use Features

          def hello do
            @feature_off :enabled_feature
            {:error, :require_code}
            @feature :enabled_feature
            {:ok, %{data: [1, 2, 3]}}
          end
        end

        assert BlockFeatureOnForEnabledFeatureWithComplexData.hello() == {:ok, %{data: [1, 2, 3]}}
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

      test "feature off at the end" do
        defmodule BlockFeatureOffAtTheEnd do
          use Features

          def hello do
            :on
            @feature_off :enabled_feature
            :off
          end
        end

        assert BlockFeatureOffAtTheEnd.hello() == :on
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

  if @test do
    test "feature1" do
      start_supervised(Features.Test)
      Features.Test.set_features(self(), [:feature1])

      assert MyModule.feature1(:ok, :any) == :ok
      assert MyModule.inner_features() == :feature1
      assert_raise CaseClauseError, fn -> MyModule.feature2(1) end
    end

    test "feature2" do
      start_supervised(Features.Test)
      Features.Test.set_features(self(), [:feature2])

      assert MyModule.feature2(true) == :ok
      assert MyModule.feature2(false) == :ko
      assert MyModule.inner_features() == :feature2
      assert_raise CaseClauseError, fn -> MyModule.feature1(1, 2) end
    end
  end
end
