defmodule TestabilityUsingFunctionReferencesTest do
  use ExUnit.Case
  doctest TestabilityUsingFunctionReferences

  test "greets the world" do
    assert TestabilityUsingFunctionReferences.hello() == :world
  end
end
