defmodule FeaturesTest do
  use ExUnit.Case
  use Features

  test "check enabled feature" do
    assert true ==
             (feature :feature_x do
                true
              end)
  end

  test "check not enabled feature" do
    assert true ==
             (feature {:no, :feature_y} do
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
