defmodule PondTest do
  use ExUnit.Case
  use Pond

  test "greets the world" do
    assert Pond.hello() == :world
  end
end
