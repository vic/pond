defmodule PondTest do
  use ExUnit.Case

  import Pond
  import Pond.Next
  import Pond.Rec

  alias Pond.Acc
  alias Pond.Rec

  import Pond.Readme

  doctest Pond
  doctest Pond.Next
  doctest Pond.Acc
  doctest Pond.Rec
end
