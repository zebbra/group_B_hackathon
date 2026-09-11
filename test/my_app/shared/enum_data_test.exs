defmodule MyApp.Shared.EnumDataTest do
  use ExUnit.Case, async: true

  defmodule Size do
    @moduledoc false

    use MyApp.Shared.EnumData,
      values: [
        small: [label: "Small", meta: [icon: "tabler-arrow-down", factor: 1]],
        large: [
          label: "Large",
          description: "A large size",
          meta: [icon: "tabler-arrow-up", amount: fn count -> "#{count * 10} units" end]
        ],
        medium: [meta: [icon: "tabler-equal"]],
        huge: []
      ]
  end

  describe "Ash.Type.Enum pass-through" do
    test "labels and descriptions reach Ash" do
      assert Size.label(:small) == "Small"
      assert Size.description(:large) == "A large size"
    end

    test "values without a label get the humanized default" do
      assert Size.label(:medium) == "Medium"
      assert Size.label(:huge) == "Huge"
    end

    test "casts valid input" do
      assert {:ok, :small} = Ash.Type.cast_input(Size, "small")
      assert {:ok, :large} = Ash.Type.cast_input(Size, :large)
    end

    test "rejects invalid input" do
      assert {:error, _reason} = Ash.Type.cast_input(Size, "tiny")
    end
  end

  describe "meta/1" do
    test "returns the meta keyword list for an atom value" do
      assert Size.meta(:small) == [icon: "tabler-arrow-down", factor: 1]
    end

    test "returns the meta keyword list for a string value" do
      assert Size.meta("medium") == [icon: "tabler-equal"]
    end

    test "returns an empty list for a value without meta" do
      assert Size.meta(:huge) == []
    end

    test "raises for a value that is not part of the enum" do
      assert_raise ArgumentError, ~r/expected one of/, fn -> Size.meta(:tiny) end
      assert_raise ArgumentError, ~r/expected one of/, fn -> Size.meta("tiny") end
    end
  end

  describe "meta/2" do
    test "returns a single meta entry" do
      assert Size.meta(:small, :icon) == "tabler-arrow-down"
      assert Size.meta("large", :icon) == "tabler-arrow-up"
    end

    test "returns nil for a missing key" do
      assert Size.meta(:small, :unknown) == nil
    end

    test "supports functions as meta values" do
      assert Size.meta(:large, :amount).(4) == "40 units"
    end
  end

  describe "options/0" do
    test "returns {label, value} tuples for select inputs" do
      assert Size.options() == [
               {"Small", :small},
               {"Large", :large},
               {"Medium", :medium},
               {"Huge", :huge}
             ]
    end
  end
end
