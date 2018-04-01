defmodule Pond.Next do
  @doc_next1 ~S"""
  Calls `fun`.

  `next/1` and all its arity variants are a convenience
  for piping functions that return other functions.

  This can be used for piping stateful
  functions returned by `Pond.pond/2`

  See the "Piping Functions" section on README.md for example usage.

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

  # Accumulating state

  For functions that return a tuple like `{state, next_fun}`.
  The accumulators from `Pond.Acc` can be used to maintain state
  while piping with `next`.

  See the module doc of `Pond.Acc` for more examples.

      iex> f = pond(:hello, fn
      ...>   pond, state = :hello ->
      ...>     {state, pond.(:world)}
      ...>   pond, state ->
      ...>     {state, pond.(state)}
      ...> end)
      ...>
      ...> f
      ...> |> Acc.into(Acc.reduce(&"#{&1} #{&2}"))
      ...> |> next()
      ...> |> next()
      ...> |> Acc.value()
      "hello world"

  """

  @doc_next ~S"""
  Calls `fun` with all remaining arguments.

  See `next/1` for usage example.
  """

  Enum.map(0..10, fn arity ->
    args = Macro.generate_arguments(arity, __MODULE__)
    @doc if arity > 0, do: @doc_next, else: @doc_next1
    def next(app, unquote_splicing(args))

    def next(app, unquote_splicing(args)) when is_function(app, unquote(arity)) do
      app.(unquote_splicing(args))
    end

    def next(app, unquote_splicing(args)) do
      Pond.App.apply(app, unquote(args))
    end
  end)
end
