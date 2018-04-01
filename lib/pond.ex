defmodule Pond do
  alias __MODULE__.App

  @readme Path.expand("../README.md", __DIR__)
  @external_resource @readme
  @moduledoc File.read!(@readme)

  @doc ~S"""
  Create a *pond* from an initial state and an `handler` function.

  The function returned by `pond/2` is just `handler` with its
  first two arguments already applied.

  That is, `handler`'s minimal arity is 2.

  All remaining arguments are supplied by the user when calling
  the result of `pond/2`.

      iex> import Pond
      ...> f = pond(:hello, fn
      ...>   pond, state = :hello ->
      ...>     {state, pond.(:world)}
      ...>   pond, state ->
      ...>     {state, pond.(state)}
      ...> end)
      ...>
      ...> assert {:hello, f} = f.()
      ...> assert {:world, f} = f.()
      ...>
      ...> :erlang.fun_info(f, :arity)
      {:arity, 0}


  In most cases `handler` will just be a function. But ponds
  can be created from anything that be applied some
  arguments to it (by implementing `Pond.Applicative`).
  """
  @spec pond(state :: any(), handler :: App.t()) :: function()
  def pond(state, handler)

  def pond(state, app) do
    arity = App.arity(app)
    fun = App.to_fun(app)
    pond_fix(arity, fun).(state)
  end

  defp pond_fix(arity, fun) when arity > 1 do
    arity = arity - 2

    fix = fn fix ->
      fn state -> pond_fun(arity, fun, fix.(fix), state) end
    end

    fix.(fix)
  end

  Enum.map(0..10, fn arity ->
    args = Macro.generate_arguments(arity, __MODULE__)

    defp pond_fun(unquote(arity), fun, fix, state) do
      fn unquote_splicing(args) ->
        fun.(fix, state, unquote_splicing(args))
      end
    end
  end)
end
