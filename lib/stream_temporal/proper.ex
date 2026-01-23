if Code.ensure_loaded?(PropCheck) do
  defmodule StreamTemporal.Proper do
    use PropCheck

    def starts_with(gen, value) do
      let [first <- value, rest <- list(gen)] do
        [first | rest]
      end
    end

    def ends_with(gen, value) do
      let [last <- value, list <- list(gen)] do
        list ++ [last]
      end
    end

    def next(gen, value, pred) do
    end

    def always(gen, value, pred) when is_function(value, 0) do
      predicated_gen =
        let [f <- gen] do
          if pred.(f), do: value.(), else: f
        end

      list(predicated_gen)
    end

    def always(gen, value, pred) when is_function(value, 1) do
      predicated_gen =
        let [f <- gen] do
          if pred.(f), do: value.(f), else: f
        end

      list(predicated_gen)
    end

    def always(gen, value, pred) do
      predicated_gen =
        let [f <- gen, v <- value] do
          if pred.(f), do: v, else: f
        end

      list(predicated_gen)
    end
  end
end
