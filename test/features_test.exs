defmodule FeaturesTest do
  use ExUnit.Case
  doctest Features

  test "greets the world" do
    assert Features.hello() == :world
  end
end
