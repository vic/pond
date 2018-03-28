defmodule Pond do
  @moduledoc ~S"""
  Pond.

  `import Pond`

  See the README.md file for an usage guide.
  """

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
      ...> :erlang.fun_info(f)[:arity]
      0

  """
  @spec pond(state :: any(), func :: function()) :: function()
  def pond(state, func) when is_function(func) do
    arity = :erlang.fun_info(func)[:arity]
    pond_fix(arity, func).(state)
  end

  defp pond_fix(arity, func) when arity > 1 do
    arity = arity - 2
    fix = fn fix ->
      fn state -> pond_fun(arity, func, fix.(fix), state) end
    end
    fix.(fix)
  end

  Enum.map(0..10, fn arity ->
    args = Macro.generate_arguments(arity, __MODULE__)
    defp pond_fun(unquote(arity), func, fix, state) do
      fn unquote_splicing(args) ->
        func.(fix, state, unquote_splicing(args))
      end
    end
  end)

end
