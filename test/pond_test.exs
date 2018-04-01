defmodule PondTest do
  use ExUnit.Case

  import Pond
  import Pond.Next

  alias Pond.Acc

  import Pond.Readme

  doctest Pond
  doctest Pond.Next
  doctest Pond.Acc
end
