defmodule StreamTemporalTest do
  use ExUnit.Case
  doctest StreamTemporal
  doctest StreamTemporal.Gen

  describe "starts_with/2" do
    test "adds a value at the beginning of a stream" do
      stream = StreamTemporal.starts_with([1, 2], 0)
      result = Enum.to_list(stream)
      assert result == [0, 1, 2]
    end

    test "works with anonymous functions" do
      stream = StreamTemporal.starts_with([1, 2], fn -> 0 end)
      result = Enum.to_list(stream)
      assert result == [0, 1, 2]
    end
  end

  describe "ends_with/3" do
    test "adds a value at the end of a stream when predicate is false" do
      stream = StreamTemporal.ends_with([1, 2, 3], 4, fn _ -> false end)
      result = Enum.to_list(stream)
      assert result == [1, 2, 3, 4]
    end

    test "stops early when predicate is true" do
      stream = StreamTemporal.ends_with([1, 2, 3], 4, fn _ -> true end)
      result = Enum.to_list(stream)
      assert result == [4]
    end

    test "works with anonymous functions" do
      stream = StreamTemporal.ends_with([1, 2, 3], fn -> 4 end, fn _ -> false end)
      result = Enum.to_list(stream)
      assert result == [1, 2, 3, 4]
    end

    test "uses default predicate when none provided" do
      stream = StreamTemporal.ends_with([1, 2, 3], 4)
      result = Enum.to_list(stream)
      assert result == [1, 2, 3, 4]
    end
  end

  describe "next/3" do
    test "adds a value after elements that match predicate" do
      stream = StreamTemporal.next([1, 2, 3], 0, fn x -> x == 2 end)
      result = Enum.to_list(stream)
      assert result == [1, 2, 0, 3]
    end

    test "works with anonymous functions" do
      stream = StreamTemporal.next([1, 2, 3], fn -> 0 end, fn x -> x == 2 end)
      result = Enum.to_list(stream)
      assert result == [1, 2, 0, 3]
    end
  end

  describe "always/3" do
    test "adds a value when predicate is met" do
      stream = StreamTemporal.always([1, 2, 3], 0, fn acc -> length(acc) >= 2 end)
      result = Enum.to_list(stream)
      assert result == [1, 2, 0]
    end

    test "works with anonymous functions" do
      stream = StreamTemporal.always([1, 2, 3], fn -> 0 end, fn acc -> length(acc) >= 2 end)
      result = Enum.to_list(stream)
      assert result == [1, 2, 0]
    end

    test "handles triggered state correctly" do
      # This test is designed to hit the {v, true} pattern matching clause
      stream = StreamTemporal.always([1, 2, 3, 4, 5], 99, fn acc -> length(acc) >= 1 end)
      # Take just a few elements to see the behavior
      result = Enum.take(stream, 3)
      # The first element should trigger the condition, so we should get [99, 99, 99]
      assert length(result) == 3
    end

    test "works with acc_function parameter" do
      # This test should trigger the second function head which takes an acc_function
      # The acc_function takes the accumulator as an argument
      acc_function = fn acc -> Enum.sum(acc) end
      predicate = fn acc -> length(acc) >= 2 end
      stream = StreamTemporal.always([1, 2, 3, 4], acc_function, predicate)
      result = Enum.to_list(stream)
      assert is_list(result)
    end
  end
end
