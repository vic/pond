defmodule Pond.Rec do

  @moduledoc ~S"""
  Function invocations recorder.
  """

  alias __MODULE__

  @type t :: %Rec{fun: function(), next: list(list(term()))}
  @rec_stop {Rec, :stop}

  defstruct [:fun, :value, {:next, []}]

  @doc ~S"""
  Creates a recorder for function `fun`.

  `fun` is usually an stateful function created with `Pond.pond/2`.

  The recorder returned by `rec/1` will deliver
  all its arguments to `fun` upon first invocation.

  If the result of calling `fun` was another function
  with the same arity as `fun`, then it will be applied
  the next invocation arguments. This happens as long as
  each function invocation results in another function
  with the same arity.

  Otherwise, when the result is not a function of
  same arity as `fun`. A new `Rec` struct is built,
  saving the last function used, and the last result
  in the `:value` field.

  Subsequent invocations to the recorder are still
  permitted. But each invocation arguments are collected
  in the recorder's `:next` field.

  To obtain the current recorder use `rec(:stop)`.

  ##### Record when no longer a pond.

  The following `x` pond will collect only up to three items.

  If the pond is called more than three times, the recorder
  will collect all subsequent invocation arguments.

      iex> x = pond([], fn
      ...>   _pond, acc, value when length(acc) == 2 ->
      ...>     [value | acc] |> Enum.reverse
      ...>   pond, acc, value ->
      ...>     pond.([value | acc])
      ...> end)
      ...>
      ...> tape =
      ...>   x
      ...>   |> rec
      ...>   |>  next(:one)
      ...>   |>  next(:two)
      ...>   |>  next(:three)
      ...>   |>  next(:four)
      ...>   |>  next(:five)
      ...>   |> rec(:stop)
      ...>
      ...> # the final value returned by `x` is saved
      ...> assert %Rec{value: [:one, :two, :three]} = tape
      ...>
      ...> # all subsequent invocations are saved
      ...> assert %Rec{next: [ [:four], [:five] ]} = tape
      ...>
      ...> # the last function that produced value
      ...> assert %Rec{fun: fun} = tape
      ...> is_function(fun, 1)
      true


  ##### Stop recorder

  Note, however, that if `rec(:stop)` is called
  before the state of `x` gets to the three-elements list.
  Then, the `Rec` struct will have a value of `nil`
  since the state is still encapulated in the last pond function.

      iex> x = pond([], fn
      ...>   _pond, acc, value when length(acc) == 2 ->
      ...>     [value | acc] |> Enum.reverse
      ...>   pond, acc, value ->
      ...>     pond.([value | acc])
      ...> end)
      ...>
      ...> tape =
      ...>   x
      ...>   |> rec(:auto)
      ...>   |>  next(:one)
      ...>   |>  next(:two)
      ...>   |> rec(:stop)
      ...>
      ...> %Rec{fun: fun, value: nil, next: []} = tape
      ...> fun.(3)
      [:one, :two, 3]


  See `rec/2` for other ways to create recorders.
  And its last example for how to play records.
  """

  @spec rec(function()) :: function()
  def rec(fun), do: rec(fun, :auto)

  @doc ~S"""
  Record function invocations.

  # Recording

  ##### `rec(fun, :auto)`

  Calling `rec/1` is equivalent to `rec(fun, :auto)`.

  That is, the recorder will just recursively
  invoke the result value while it keeps being a same
  arity function. Otherwise the recorder starts
  collecting subsequent invocation arguments.

  See the documentation example of `rec/1`.

  ##### `rec(fun, :rec)`

  The `:rec` action will *immediatly* start recording
  without ever invoking `fun`.

      iex> tape =
      ...>   (&IO.puts/1)
      ...>   |> rec(:rec)
      ...>   |> next("What")
      ...>   |> next("a")
      ...>   |> next("wonderful")
      ...>   |> next("world")
      ...>   |> rec(:stop)
      ...>
      ...> assert %Rec{value: nil} = tape
      ...>
      ...> %Rec{next: next} = tape
      ...> assert [["What"], ["a"], ["wonderful"], ["world"]] = next
      ...>
      ...> %Rec{fun: fun} = tape
      ...> fun
      &IO.puts/1


  ##### `rec(arity, :rec)`

  Another way to create a recorder is by simply
  specifying the function arity.

  This way you can create a recorder and hand it
  to some other function to simply use it. Then
  you could stop the recording and get what the
  other function called on it.

      iex> tape =
      ...>   rec(2, :rec)
      ...>   |> next("What", "a")
      ...>   |> next("wonderful", "world")
      ...>   |> rec(:stop)
      ...>
      ...> assert %Rec{value: nil} = tape
      ...>
      ...> %Rec{next: next} = tape
      ...> assert [["What", "a"], ["wonderful", "world"]] = next
      ...>
      ...> %Rec{fun: fun} = tape
      ...> fun
      nil

  # Playing a record

      iex> x = pond([], fn
      ...>   _pond, acc, value when length(acc) == 2 ->
      ...>     [value | acc] |> Enum.reverse
      ...>   pond, acc, value ->
      ...>     pond.([value | acc])
      ...> end)
      ...>
      ...> tape = %Rec{fun: x, next: [[:hello], [:beautiful], [:world]]}
      ...> played = rec(tape, :play)
      ...>
      ...> assert %Rec{value: value, next: []} = played
      ...> value
      [:hello, :beautiful, :world]

  """

  @spec rec(rec :: t(), action :: :play) :: t()
  @spec rec(fun :: function(), action :: :stop) :: t()
  @spec rec(arity :: integer(), action :: :rec) :: function()
  @spec rec(fun :: function(), action :: :rec | :auto) :: function()
  def rec(fun, action)

  def rec(fun, :auto) when is_function(fun) do
    rec = fun |> fun_arity |> rec_fun
    Pond.pond(fun, rec)
  end

  def rec(fun, :rec) when is_function(fun) do
    rec = fun |> fun_arity |> rec_fun
    Pond.pond(%Rec{fun: fun}, rec)
  end

  def rec(arity, :rec) when is_integer(arity) do
    rec = rec_fun(arity)
    Pond.pond(%Rec{}, rec)
  end

  def rec(rec, :stop) when is_function(rec) do
    stops = fun_args(rec, @rec_stop)
    apply(rec, stops)
  end

  def rec(%Rec{fun: fun, next: next}, :play) do
    rec = rec(fun, :auto)
    next
    |> Enum.reduce(rec, fn args, f -> apply(f, args) end)
    |> rec(:stop)
  end

  defp fun_args(fun, value) do
    Stream.repeatedly(fn -> value end)
    |> Enum.take(fun_arity(fun))
  end

  defp fun_arity(fun) when is_function(fun) do
    {:arity, arity} = :erlang.fun_info(fun, :arity)
    arity
  end

  Enum.map(0..10, fn arity ->
    args = Macro.generate_arguments(arity, __MODULE__)
    stops = Enum.map(args, fn _ -> @rec_stop end)
    defp rec_fun(unquote(arity)) do
      fn
        _pond, rec = %Rec{next: nxt}, unquote_splicing(stops) ->
          %Rec{ rec | next: Enum.reverse(nxt) }

        _pond, f, unquote_splicing(stops) when is_function(f, unquote(arity)) ->
          %Rec{fun: f}

        pond, rec = %Rec{next: nxt}, unquote_splicing(args) ->
          pond.(%Rec{ rec | next: [unquote(args) | nxt] })

        pond, f, unquote_splicing(args) when is_function(f, unquote(arity)) ->
          value = f.(unquote_splicing(args))
          case value do
            vf when is_function(vf, unquote(arity)) ->
              pond.(vf)
            _ ->
              pond.(%Rec{fun: f, value: value})
          end

      end
    end
  end)

end
