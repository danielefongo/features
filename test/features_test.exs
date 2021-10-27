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
      defmodule FeatureOn do
        use Features

        @feature :feature_x
        def hello, do: :hello
      end

      assert FeatureOn.hello() == :hello
    end

    test "feature off" do
      defmodule FeatureOff do
        use Features

        @feature_off :feature_y
        def hello, do: :hello
      end

      assert FeatureOff.hello() == :hello
    end

    test "feature on for undefined feature" do
      defmodule FeatureOnForUndefniedFeature do
        use Features

        @feature :feature_y
        def hello, do: :hello
      end

      assert_raise UndefinedFunctionError, fn -> FeatureOnForUndefniedFeature.hello() end
    end

    test "feature off for defined feature" do
      defmodule FeatureOffForDefinedFeature do
        use Features

        @feature_off :feature_x
        def hello, do: :hello
      end

      assert_raise UndefinedFunctionError, fn -> FeatureOffForDefinedFeature.hello() end
    end

    test "feature off not propagated" do
      defmodule FeatureOffNotPropagated do
        use Features

        @feature_off :feature_x
        def hello, do: :hello

        def present?, do: true
      end

      assert FeatureOffNotPropagated.present?() == true
    end
  end
end
