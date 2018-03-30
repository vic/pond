defmodule Pond.Next do

  @doc_next1 ~S"""
  Calls `func`.

  `next/1` and all its arity variants are a convenience
  for piping functions that return other functions.

  # Example

  The following example uses `next/2` and `next/3`:

      iex> import Pond.Next
      ...>
      ...> f = fn x ->
      ...>    fn y, z ->
      ...>      x + y + z
      ...>    end
      ...> end
      ...>
      ...> f
      ...> |> next(10)
      ...> |> next(200, 3)
      213


  This can be used for piping stateful
  functions returned by `Pond.pond/2`

  See the "Elixir Generators" section on README.md for example usage.
  """

  @doc_next ~S"""
  Calls `func` with all remaining arguments.

  See `next/1` for usage example.
  """

  @spec next(function()) :: any()
  def next(func)

  Enum.map(0..10, fn arity ->
    args = Macro.generate_arguments(arity, __MODULE__)
    @doc (if arity > 0, do: @doc_next, else: @doc_next1)
    def next(func, unquote_splicing(args)) when is_function(func, unquote(arity)) do
      func.(unquote_splicing(args))
    end
  end)

end
