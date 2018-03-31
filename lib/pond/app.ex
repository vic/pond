defmodule Pond.App do

  @moduledoc ~S"""
  Pond Applicative.

  In Pond, an Applicative is something that can
  take arguments and produce another value.
  """

  alias Pond.Applicative
  import Kernel, except: [apply: 2]

  @type t :: Applicative.t()

  @doc ~S"""
  Returns the number of arguments that an applicative can take.
  """
  @spec arity(t()) :: integer()
  def arity(app), do: Applicative.arity(app)

  @doc ~S"""
  Applies arguments into an applicative.
  """
  @spec apply(t(), list()) :: term()
  def apply(app, args), do: Applicative.apply(app, args)

  @doc ~S"""
  Creates a function from an applicative.
  """
  @spec to_fun(t()) :: fun()
  def to_fun(app)
  def to_fun(fun) when is_function(fun), do: fun
  def to_fun(app), do: app_fun(app, arity(app))

  Enum.map(0..10, fn arity ->
    args = Macro.generate_arguments(arity, __MODULE__)
    defp app_fun(app, unquote(arity)) do
      fn unquote_splicing(args) -> apply(app, unquote(args)) end
    end
  end)

end

defprotocol Pond.Applicative do
  @typedoc "Anything implementing the `Pond.Applicative` protocol"
  @type t :: term()

  @spec arity(t()) :: integer()
  def arity(app)

  @spec apply(t(), list()) :: term()
  def apply(app, args)
end


defimpl Pond.Applicative, for: Function do
  def arity(fun) do
    {:arity, arity} = :erlang.fun_info(fun, :arity)
    arity
  end

  def apply(fun, args) do
    :erlang.apply(fun, args)
  end
end

defimpl Pond.Applicative, for: Tuple do
  alias Pond.App

  def arity({_acc, app}) do
    App.arity(app)
  end

  def apply({acc, app}, args) do
    {state, next_app} = App.apply(app, args)
    next_state = App.apply(acc, [state])
    {next_state, next_app}
  end
end
