defmodule Pond.App do

  @moduledoc ~S"""
  Pond Applicative.

  In Pond, an Applicative is something that can
  take arguments and produce another value.
  """

  alias __MODULE__.Protocol
  import Kernel, except: [apply: 2]

  @typep app :: term()

  @doc ~S"""
  Returns the number of arguments that an applicative can take.
  """
  @spec arity(app()) :: integer()
  def arity(app), do: Protocol.arity(app)

  @doc ~S"""
  Applies arguments into an applicative.
  """
  @spec apply(app(), list()) :: term()
  def apply(app, args), do: Protocol.apply(app, args)

  @doc ~S"""
  Creates a function from an applicative.
  """
  @spec to_fun(app()) :: fun()
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

defprotocol Pond.App.Protocol do
  @doc false
  def arity(app)
  def apply(app, args)
end


defimpl Pond.App.Protocol, for: Function do
  def arity(fun) do
    {:arity, arity} = :erlang.fun_info(fun, :arity)
    arity
  end

  def apply(fun, args) do
    :erlang.apply(fun, args)
  end
end

defimpl Pond.App.Protocol, for: Tuple do
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
