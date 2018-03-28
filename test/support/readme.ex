defmodule Pond.Readme do
  @readme Path.expand("../../README.md", __DIR__)
  @external_resource @readme
  @moduledoc File.read!(@readme)
end
