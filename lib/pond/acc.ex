defmodule Pond.Acc do
  import Pond

  @idle {__MODULE__, :idle}
  @halt {__MODULE__, :halt}

  @moduledoc ~S"""
  Functions for accumulating state.

  State accumulators are useful when combined with
  `Pond.Next` for piping while preserving previous
  invocations state.

  For example, piping our hello world example and
  accumulating its values into a list:

      iex> f = pond(:hello, fn
      ...>   pond, state = :hello ->
      ...>     {state, pond.(:world)}
      ...>   pond, state ->
      ...>     {state, pond.(state)}
      ...> end)
      ...>
      ...> f
      ...> |> Acc.into(Acc.list())
      ...> |> next()
      ...> |> next()
      ...> |> Acc.value()
      [:hello, :world]


  `Pond.Next` can use this module's functions in order
  to accumulate state for functions that follow
  the convention of returning `{value, next_fun}`.

  This module provides some accumulators for common
  cases. However, if your function return a different
  structure you can easily use these as reference to
  build your own.


  Accumulators are themselves just *pond*s. So they
  can be used independently. For example:

      iex> f = Acc.list()
      ...> f = f.(:hello)
      ...> f = f.(:world)
      ...> Acc.value(f)
      [:hello, :world]
  """

  @type pond :: (... -> term())
  @type acc :: (term() -> term())
  @type acc_pond :: (term() -> acc())
  @type acc_and_pond :: {acc_pond(), pond()}
  @type reducer :: (term(), term() -> term())

  @doc ~S"""
  Combines a function and an accumulator in a tuple as expected by `Pond.Next`.

      iex> f = pond(:hello, fn
      ...>   pond, state = :hello ->
      ...>     {state, pond.(:world)}
      ...>   pond, state ->
      ...>     {state, pond.(state)}
      ...> end)
      ...>
      ...> assert {acc, ^f} = f |> Acc.into(Acc.list())
      ...> assert acc == Acc.list()
      ...> assert is_function(acc, 1)
      true
  """
  @spec into(pond :: pond(), acc :: acc_pond()) :: acc_and_pond()
  def into(pond, acc) do
    {acc, pond}
  end

  @doc ~S"""
  Extracts the current value from the accumulator.

  Normally, this will be the last step of a pipe, in order
  to extract the accumulated state.

  See this module doc.
  """
  @spec value(acc() | acc_and_pond()) :: term()
  def value(acc)

  def value({acc, _pond}) when is_function(acc, 1) do
    acc.(@halt)
  end

  def value(acc) when is_function(acc, 1) do
    acc.(@halt)
  end

  @doc ~S"""
  Creates a new list accumulator.

  Extracting value from this accumulator
  returns a list of all values yield to it.

  See this module doc.
  """
  @spec list() :: acc_pond()
  def list do
    pond(@idle, fn
      _pond, @idle, @halt ->
        []

      _pond, state, @halt ->
        state |> Enum.reverse()

      pond, @idle, state ->
        pond.([state])

      pond, acc, state ->
        pond.([state | acc])
    end)
  end

  @doc ~S"""
  Creates an accumulator that stores only the
  last value given to it.

      iex> f = pond(:hello, fn
      ...>   pond, state = :hello ->
      ...>     {state, pond.(:world)}
      ...>   pond, state ->
      ...>     {state, pond.(state)}
      ...> end)
      ...>
      ...> f
      ...> |> Acc.into(Acc.last())
      ...> |> next()
      ...> |> next()
      ...> |> Acc.value()
      :world

  """
  @spec last() :: acc_pond()
  def last do
    pond(@idle, fn
      _pond, @idle, @halt ->
        nil

      _pond, state, @halt ->
        state

      pond, _state, value ->
        pond.(value)
    end)
  end

  @doc ~S"""
  Creates an accumulator that reduces state

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
  @spec reduce(reducer()) :: acc_pond()
  def reduce(reducer) do
    pond(@idle, fn
      _pond, @idle, @halt ->
        nil

      _pond, state, @halt ->
        state

      pond, @idle, value ->
        pond.(value)

      pond, acc, value ->
        pond.(reducer.(acc, value))
    end)
  end

  @doc ~S"""
  Creates an accumulator that reduces state
  starting with an initial value.

      iex> f = pond(:hello, fn
      ...>   pond, state = :hello ->
      ...>     {state, pond.(:world)}
      ...>   pond, state ->
      ...>     {state, pond.(state)}
      ...> end)
      ...>
      ...> f
      ...> |> Acc.into(Acc.reduce(&"#{&1} #{&2}", "yay"))
      ...> |> next()
      ...> |> next()
      ...> |> Acc.value()
      "yay hello world"
  """
  @spec reduce(reducer(), initial_value :: term()) :: acc_pond()
  def reduce(reducer, initial_value) do
    pond(initial_value, fn
      _pond, state, @halt ->
        state

      pond, acc, value ->
        pond.(reducer.(acc, value))
    end)
  end
end
