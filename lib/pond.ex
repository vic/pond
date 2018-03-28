defmodule Pond do
  @moduledoc """
  Pond.

  `use Pond`

  See the README.md file for an usage guide.
  """

  @doc false
  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end

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
