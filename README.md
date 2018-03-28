# Pond - State aware Elixir functions without spawning processes.

[![Travis](https://img.shields.io/travis/vic/pond.svg)](https://travis-ci.org/vic/pond)
[![Hex.pm](https://img.shields.io/hexpm/v/pond.svg?style=flat-square)](https://hexdocs.pm/pond)

Pond is an Elixir library for creating functions that are able to keep state between 
invocations while still being functionally pure.

Pond functions don't require you to spawn a new process ala GenServer, GenStage, etc.
However a pond function can easily be part of them when needed just like any other function.

#### Wait, arent processes *the* nice thing about the BEAM?

Spawning a new process just to keep state is not always a good idea.

Dont get me wrong, one of the *best* features of the BEAM is that it's very cheap
to create tons of processes and supervise them.

However abusing spawn, just because you want to keep state, well, that's certainly 
not the smartest thing. If you created zillions of tiny processes all data between them 
would actually be duplicated on each message pass, since processes prefer to share nothing, 
messages get copied between them when sent.

Think about the *Server* part in _GenServer_, it sounds like something intended
to be used by many *clients* something much more complex than just maintaining state.

Some useful resources:

[python generators thread on EF](https://elixirforum.com/t/python-generators-equivalent/2806/10)

[spawn or not](http://theerlangelist.com/article/spawn_or_not)

## `use Pond`

A *pond* is created by combining an initial state and a function.

`pond/2` returns a function that can be invoked without explicitly
giving a state to it. If you are curious about how it's done, 
[Pond's core is just a simple closure](https://github.com/vic/pond/tree/master/pond.ex)

##### Hello

The most basic example would be a function that when called just
returns it's initial state.

```elixir
iex> f = pond(:hello, fn 
...>   _, state -> state
...> end)
...> f.()
:hello
```

The previous example however, is not really interesting as it's not
doing much with the state, except returning it at first invocation.

##### Hello World

Let's create another function that can alter it's own internal state:

```elixir
iex> f = pond(:hello, fn 
...>   pond, state = :hello ->
...>     {state, pond.(:world)}
...>   pond, state ->
...>     {state, pond.(state)}
...> end)
...>
...> assert {:hello, f} = f.()
...> assert {:world, f} = f.()
...> 
...> elem(f.(), 0)
:world
```

A couple of things we have to mention about the previous example:

Since Elixir is a functional language, you can see that calling `f.()`
will return a tuple with the current state and the next function to
be called (a *pond* with updated state).

Updating the state is done by calling the current pond with a new state.
In our example, when `state = :hello`, the next function is built
by changing the state to `:world`, in `pond.(:world)`.

The last line of our example shows that once we are in the `:world`
state, it wont change anymore.

As you can see, our functions are actually pure, it's just that we 
are getting an *updated function* to call the next time. Exactly
the same as when you `Map.put` something and get a *new* map. The nice
thing about this is, the state is managed internally by the pond
itself and for the user the state is abstracted away.

##### Ever growing

Let's create a function that cycles an array of ints but on every cycle
increments the number of decimal positions.

In the code bellow, note that the `[]` stop condition creates a new pond
increasing `m` and automatically calls it:

```elixir
def growing(ints) do
  pond({[1, 2, 3], 1}, fn
    pond, {[n | rest], m}  ->
      { n * m, pond.({rest, m}) }
    pond, {[], m} ->
      pond.({ints, m * 10}).()
  end)
end
```

```elixir
iex> f = growing([1, 2, 3])
...>
...> assert {1, f} = f.()
...> assert {2, f} = f.()
...> assert {3, f} = f.()
...>
...> assert {10, f} = f.()
...> assert {20, f} = f.()
...> assert {30, f} = f.()
...>
...> assert {100, f} = f.()
...> f.() |> elem(0)
200
```

### Multiple Arguments

So, basically a *pond* is a function that is already capturing it's
state and is just waiting to be called with some other arguments from
the user. 

Up to now, if you notice our previous examples, all of them yield a 
function with zero arity `f.()`. However, you can create a *pond* that
takes any number of arguments.

Our next example, `scan`, yields a function that will take a single argument.
Either the `:run` atom to extract the state or a value to be accumulated in
the state.

```elixir
def scan(f, acc) do
  pond(acc, fn
    _, acc, :run ->
      acc
    pond, acc, value ->
      pond.(f.(acc, value))
  end)
end
```

The `Pond.Next` module provides `next`. A convenience that simply takes a function 
as first argument and invokes it with all remaining arguments.

This allows us to nicely pipe stateful functions as they are being produced from previous
steps.

For example, `next/2` is:

```
def next(fun, arg), do: fun.(arg)
```

```elixir
iex> import Pond.Next
...> (&Kernel.+/2)
...> |> scan(0)
...> |> next(10)
...> |> next(3)
...> |> next(200)
...> |> next(:run)
213
```

### Elixir Callbags

[Callbag](https://github.com/callbag/callbag) is a specification for creating
fast pull/push streams on JavaScript land.

Callbags are simple functions that following a communication protocol
between them can implement the so-called, *reactive programming* paradigm.

Callbags are also being ported to other [platforms](https://github.com/kitten/wonka),
since callbags have no core-library, and let you achieve the same *reactivity*
without requiring full libraries like Rx and friends.

Ok, enought about JS, let's get back to Elixir.

First, let's define `foo`, a *source*, in Callbag parlance, a function
that generates data (like GenStage's *producer*).

The `foo` *pond* starts with an initial `:idle` state. Awaiting to be called
with `(0, sink)`. This, in Callbag, is known as the handshake part of the
protocol, the source must then greet (`0`) back the sink.

In our *pond*, upon being greeted by a skink `0`, we update the state `source.(sink)` to
save a reference to the sink that is greeting us, and then just greet back `sink.(0, source)`.

Once the handshake is complete, the sink can demand (`1`) data from us when it feels like. 
We say `foo` is a *pullable* stream.

Sometimes, a pullable stream can take `(1, data)`, where data can be things like 
the amount of data desired by the sink (like GenStage's demand). 
In our example, we just ignore this.

Finally, after being asked for data, we send (`1`) some `:hello`, `:world` thingies back 
to the sink, and tell it we are done `(2, nil)` without error, and that there wont 
any more data coming from us.

```elixir
def foo() do
  pond(:idle, fn
    source, :idle, 0, sink ->
      source = source.(sink)
      sink.(0, source)

    _source, sink, 1, _data ->
      sink
      |> next(1, :hello)
      |> next(1, :world)
      |> next(2, nil)
  end)
end
```

Now let's implement `bar`, a _sink_.

Just like in our previous code, `bar` also starts with an `:idle` state.
Expecting a greeting from a source, once received, we update the sink
internal status `sink.([])` with an empty list where we will accumulate
messages from the source.

When the source greets us back, our state already is `[]`, so we receive
`bound`, that is, the sink *subscribed* to the source, each callbag with
it's state ready to exchange data. In our example, we simply return this
as our test bellow is the one that starts the demand for data.

Once we are receiving data from the source, we simply collect it and update
the sink state `sink.([data | acc])`.

Once the source tell us that it is done, we simply reverse our accumulator
and return that.


```elixir
def bar() do
  pond(:idle, fn
    sink, :idle, 0, source ->
      sink = sink.([])
      source.(0, sink)
    _sink, [], 0, bound ->
      bound
    sink, acc, 1, data ->
      sink.([data | acc])
    _sink, acc, 2, nil ->
      acc |> Enum.reverse
  end)
end
```

And now, let's wire `foo` and `bar` to work together.

```elixir
iex> source = foo()
...> sink = bar()
...> bound = sink.(0, source) # bar meets foo
...> bound.(1, nil) # demand data
[:hello, :world]
```

This way you could use `Pond` to create Elixir Callbags that dont spawn
a new process for *every* operation.

## Installation

```elixir
def deps do
  [
    {:pond, "~> 0.1"}
  ]
end
```

Documentation can be found at [https://hexdocs.pm/pond](https://hexdocs.pm/pond).

