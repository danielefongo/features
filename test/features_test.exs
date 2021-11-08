defmodule FeaturesTest do
  use ExUnit.Case
  use Features.Test

  @test Application.fetch_env!(:features, :test)

  defmodule RuntimeModule do
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

  defmodule CompileModule do
    use Features

    @feature :enabled_feature
    def enabled_feature_on?(), do: true

    @feature_off :enabled_feature
    def enabled_feature_off?(), do: :should_rise

    @feature :not_enabled_feature
    def not_enabled_feature_on?(), do: :should_rise

    @feature_off :not_enabled_feature
    def not_enabled_feature_off?(), do: true

    def inner_features do
      @feature :enabled_feature
      :enabled_feature
      @feature :not_enabled_feature
      :not_enabled_feature
    end
  end

  if not @test do
    test "enabled_feature" do
      assert CompileModule.enabled_feature_on?() == true
      assert_raise UndefinedFunctionError, fn -> CompileModule.enabled_feature_off?() end
      assert CompileModule.inner_features() == :enabled_feature
    end

    test "not_enabled_feature" do
      assert CompileModule.not_enabled_feature_off?() == true
      assert_raise UndefinedFunctionError, fn -> CompileModule.not_enabled_feature_on?() end
    end
  end

  if @test do
    test "feature1" do
      start_supervised(Features.Test)
      Features.Test.set_features(self(), [:feature1])

      assert RuntimeModule.feature1(:ok, :any) == :ok
      assert RuntimeModule.inner_features() == :feature1
      assert_raise CaseClauseError, fn -> RuntimeModule.feature2(1) end
    end

    test "feature2" do
      start_supervised(Features.Test)
      Features.Test.set_features(self(), [:feature2])

      assert RuntimeModule.feature2(true) == :ok
      assert RuntimeModule.feature2(false) == :ko
      assert RuntimeModule.inner_features() == :feature2
      assert_raise CaseClauseError, fn -> RuntimeModule.feature1(1, 2) end
    end
  end
end
