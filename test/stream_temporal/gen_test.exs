defmodule StreamTemporal.GenTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  doctest StreamTemporal.Gen
  alias StreamTemporal.Gen

  setup do
    [list_of_int: integer() |> list_of(), pred: Gen.eq(0)]
  end

  describe "always" do
    property "only some_gen after pred", %{list_of_int: gen, pred: pred} do
      check all list <- Gen.bind_always(gen, pred, :always) do
        assert list
               # starts at true, for empty lists
               |> Enum.reduce(true, fn
                 # it shouldn't allow 0 at the end
                 0, true -> false
                 # it should only allow `:always` after a `0`
                 :always, false -> true
                 # never change for just a number
                 a, acc when is_integer(a) or a == :always -> acc
               end)
      end
    end

    @tag skip: true
    @tag timeout: :infinity
    property "never ends with pred value", %{list_of_int: gen, pred: pred} do
      check all list <- Gen.bind_always(gen, pred, :always), max_runs: 250_000 do
        refute List.last(list) == 0
      end
    end
  end

  describe "eventually" do
    property "some_gen sometime after pred", %{list_of_int: gen, pred: pred} do
      check all list <- Gen.bind_eventually(gen, pred, :eventually) do
        assert list
               |> Enum.reduce(0, fn
                 # increment when pred matches
                 0, acc -> acc + 1
                 # decrement when value matches
                 :eventually, acc -> acc - 1
                 # ensure we don't ever go have value without pred
                 _v, acc when acc >= 0 -> acc
               end) == 0
      end
    end
  end

  describe "none_after" do
    property "no pred after pred", %{list_of_int: gen, pred: pred} do
      check all list <- Gen.bind_none_after(gen, pred) do
        assert Enum.count(list, pred) in [0, 1]
      end
    end
  end

  describe "next" do
    property "always some_gen after pred", %{list_of_int: gen, pred: pred} do
      check all list <- Gen.bind_next(gen, pred, :next) do
        assert list
               |> Enum.with_index()
               |> Enum.reduce(%{}, fn
                 {0, i}, acc ->
                   Map.put(acc, i, true)

                 {:next, i}, acc ->
                   assert Map.get(acc, i - 1)
                   acc

                 {_, i}, acc ->
                   refute Map.get(acc, i - 1)
                   acc
               end)
      end
    end
  end

  describe "starts_with" do
    property "always some_gen to start with", %{list_of_int: gen} do
      check all list <- Gen.bind_starts_with(gen, :starts_with) do
        case list do
          [] -> assert true
          [_ | _] -> assert hd(list) == :starts_with
        end
      end
    end
  end

  describe "ends_with" do
    property "always some_gen to end with", %{list_of_int: gen} do
      check all list <- Gen.bind_ends_with(gen, :ends_with) do
        case list do
          [] -> assert true
          [_ | _] -> assert hd(Enum.reverse(list)) == :ends_with
        end
      end
    end
  end
end
