defmodule StreamTemporal.ProperTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  alias StreamTemporal.Proper

  describe "starts_with" do
    property "generates lists where the first element is the specified value" do
      gen = Proper.starts_with(nonempty(sized(0, one_of([0, 1, 2]))), 42)

      check all sample <- gen do
        assert List.first(sample) == 42
      end
    end

    property "generates lists of the correct length" do
      gen = Proper.starts_with(list_of_1(integer()), 42)

      check all sample <- gen do
        assert length(sample) > 0
        assert length(sample) > 1
      end
    end
  end

  describe "ends_with" do
    property "generates lists where the last element is the specified value" do
      gen = Proper.ends_with(nonempty(sized(0, one_of([0, 1, 2]))), 99)

      check all sample <- gen do
        assert List.last(sample) == 99
      end
    end

    property "generates lists of the correct length" do
      gen = Proper.ends_with(list_of_1(integer()), 99)

      check all sample <- gen do
        assert length(sample) > 0
        assert length(sample) > 1
      end
    end
  end

  describe "always (zero-arity function)" do
    property "replaces elements matching predicate with value from zero-arity function" do
      gen = Proper.always(nonempty(sized(0, one_of([0, 1, 2]))), fn -> 0 end, &(&1 < 0))

      check all list <- gen do
        Enum.all?(list, &(not (&1 < 0)))
      end
    end
  end

  describe "always (one-arity function)" do
    property "replaces elements matching predicate with transformed value from one-arity function" do
      gen = Proper.always(nonempty(sized(0, one_of([0, 1, 2]))), &abs/1, &(&1 < 0))

      check all list <- gen do
        Enum.all?(list, &(not (&1 < 0)))
      end
    end
  end

  describe "always (generator)" do
    property "replaces elements matching predicate with generator value" do
      gen = Proper.always(nonempty(sized(0, one_of([0, 1, 2]))), one_of([1, 2, 3]), &(&1 < 0))

      check all list <- gen do
        Enum.all?(list, &(not (&1 < 0)))
      end
    end
  end

  describe "next" do
    test "returns empty list (unimplemented)" do
      assert Proper.next(list_of_1(integer()), 42, &(&1 == 0)) == []
    end
  end
end
