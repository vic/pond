defmodule Pond do
  @moduledoc """
  Documentation for Pond.
  """

  @doc false
  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__).Core
    end
  end

  @doc """
  Hello world.

  ## Examples

      iex> Pond.hello
      :world

  """
  def hello do
    :world
  end
end
