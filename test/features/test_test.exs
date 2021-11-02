defmodule Features.TestTest do
  use ExUnit.Case, async: true
  use Features.Test
  alias Features.Test

  featured_test "enabled?", features: [:feature1] do
    assert Test.enabled?(:feature1) == true
    assert Test.enabled?(:feature2) == false
  end

  featured_test "disabled?", features: [:feature1] do
    assert Test.disabled?(:feature1) == false
    assert Test.disabled?(:feature2) == true
  end
end
