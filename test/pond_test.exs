defmodule PondTest do
  use ExUnit.Case
  import Pond
  import Pond.Next
  import Pond.Rec
  alias Pond.Rec
  doctest Pond
  doctest Pond.Next
  doctest Pond.Rec
end
