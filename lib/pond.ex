defmodule Pond do
  alias __MODULE__.App

  @readme Path.expand("../README.md", __DIR__)
  @external_resource @readme
  @moduledoc File.read!(@readme)

  @doc ~S"""
  Create a *pond* from an initial state and a handler function.

  The function returned by `pond/2` is just `func` with its
  first two arguments already applied.

  That is, `func`'s minimal arity is 2.

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

  """
  @spec pond(state :: any(), app :: App.t()) :: function()
  def pond(state, app) do
    arity = App.arity(app)
    pond_fix(arity, app).(state)
  end

  defp pond_fix(arity, app) when arity > 1 do
    arity = arity - 2

    fix = fn fix ->
      fn state -> pond_fun(arity, app, fix.(fix), state) end
    end

    fix.(fix)
  end

  Enum.map(0..10, fn arity ->
    args = Macro.generate_arguments(arity, __MODULE__)

    defp pond_fun(unquote(arity), app, fix, state) do
      fn
        unquote_splicing(args) when is_function(app, unquote(arity)) ->
          app.(fix, state, unquote_splicing(args))

        unquote_splicing(args) ->
          App.apply(app, [fix, state, unquote_splicing(args)])
      end
    end
  end)
end
