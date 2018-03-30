defmodule Pond.Readme do
  import Pond
  import Pond.Next

  def growing(ints) do
    pond({ints, 1}, fn
      pond, {[n | rest], m}  ->
        { n * m, pond.({rest, m}) }
      pond, {[], m} ->
        pond.({ints, m * 10}).()
    end)
  end

  def reduce(f, acc) do
    pond(acc, fn
      _, acc, :halt ->
        acc
      pond, acc, value ->
        pond.(f.(acc, value))
    end)
  end

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

  def bar() do
    pond(:idle, fn
      sink, :idle, 0, source ->
        sink = sink.([])
      source.(0, sink)
      _sink, [], 0, source_sink ->
        source_sink
      sink, acc, 1, data ->
        sink.([data | acc])
      _sink, acc, 2, nil ->
        acc |> Enum.reverse
    end)
  end

end
