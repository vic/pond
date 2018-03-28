defmodule Pond.ModuledocsTest do
  use ExUnit.Case
  use Pond
  doctest Pond.Readme
  doctest Pond
end
