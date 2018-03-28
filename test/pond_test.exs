defmodule PondTest do
  use ExUnit.Case
  doctest Pond

  test "greets the world" do
    assert Pond.hello() == :world
  end
end
