defmodule Pond.Next do

  Enum.map(0..10, fn arity ->
    args = Macro.generate_arguments(arity, __MODULE__)
    @doc false
    def next(pond, unquote_splicing(args)) when is_function(pond, unquote(arity)) do
      pond.(unquote_splicing(args))
    end
  end)

end
