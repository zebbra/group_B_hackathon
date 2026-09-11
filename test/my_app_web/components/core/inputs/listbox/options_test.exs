defmodule MyAppWeb.Components.Core.Inputs.Listbox.OptionsTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias MyAppWeb.Components.Core.Inputs.Listbox.Options

  defp flat(n), do: for(i <- 1..n, do: {"opt-#{String.pad_leading("#{i}", 2, "0")}", "#{i}"})

  defp selects(values) do
    values = Enum.map(values, &to_string/1)
    fn value -> to_string(value) in values end
  end

  defp none, do: fn _value -> false end

  defp off({label, value}), do: %{label: label, value: value, disabled: true}

  defp values_of(options), do: Enum.map(options, &Options.item_value/1)

  describe "accessors" do
    test "read label, value, display and search from tuples and maps" do
      assert Options.item_label({"Alpha", "1"}) == "Alpha"
      assert Options.item_value({"Alpha", "1"}) == "1"
      assert Options.item_display({"Alpha", "1"}) == "Alpha"
      assert Options.item_search({"Alpha", "1"}) == "Alpha"

      item = %{label: "admin", value: "1", display: "AADB - admin", search: "AADB admin"}
      assert Options.item_label(item) == "admin"
      assert Options.item_display(item) == "AADB - admin"
      assert Options.item_search(item) == "AADB admin"
    end

    test "item_badge is optional and stringifies non-binaries" do
      assert Options.item_badge(%{label: "AGF", value: "1", badge: 2790}) == "2790"
      assert Options.item_badge(%{label: "AGF", value: "1", badge: "X-1"}) == "X-1"

      refute Options.item_badge(%{label: "AGF", value: "1", badge: nil})
      refute Options.item_badge(%{label: "AGF", value: "1", badge: ""})
      refute Options.item_badge(%{label: "AGF", value: "1"})
      refute Options.item_badge({"Alpha", "1"})
    end

    test "slot_arg merges label, value, selected and disabled into map options" do
      assert Options.slot_arg({"Alpha", "1"}, true) == %{
               label: "Alpha",
               value: "1",
               selected: true,
               disabled: false
             }

      assert Options.slot_arg(%{label: "Alpha", value: "1", extra: :keep}, false) ==
               %{label: "Alpha", value: "1", extra: :keep, selected: false, disabled: false}

      assert Options.slot_arg(%{label: "Alpha", value: "1", disabled: true}, false) ==
               %{label: "Alpha", value: "1", selected: false, disabled: true}
    end

    test "item_disabled reads the flag from maps and never from tuples" do
      assert Options.item_disabled(%{label: "Alpha", value: "1", disabled: true})
      refute Options.item_disabled(%{label: "Alpha", value: "1", disabled: false})
      refute Options.item_disabled(%{label: "Alpha", value: "1", disabled: nil})
      refute Options.item_disabled(%{label: "Alpha", value: "1"})
      refute Options.item_disabled({"Alpha", "1"})
    end

    test "item_disabled_reason is given only for options that are actually disabled" do
      assert Options.item_disabled_reason(%{
               label: "Alpha",
               value: "1",
               disabled: true,
               disabled_reason: "Retired in 2025"
             }) == "Retired in 2025"

      # a reason without the flag would explain something the user can still pick
      refute Options.item_disabled_reason(%{
               label: "Alpha",
               value: "1",
               disabled_reason: "Retired in 2025"
             })

      refute Options.item_disabled_reason(%{label: "Alpha", value: "1", disabled: true})

      refute Options.item_disabled_reason(%{
               label: "Alpha",
               value: "1",
               disabled: true,
               disabled_reason: ""
             })

      refute Options.item_disabled_reason({"Alpha", "1"})
    end

    test "find_option resolves through groups and refuses blanks" do
      groups = [%{label: "AADB", options: [%{label: "admin", value: "1"}]}]

      assert Options.find_option(groups, "1") == %{label: "admin", value: "1"}
      assert Options.find_option(groups, "9") == nil
      assert Options.find_option(groups, nil) == nil
      assert Options.find_option(groups, "") == nil
      assert Options.find_option([{"Alpha", "1"}], "1") == {"Alpha", "1"}
    end

    test "same? never treats a blank as equal to anything" do
      assert Options.same?("1", "1")
      assert Options.same?(:alap, "alap")
      refute Options.same?(nil, nil)
      refute Options.same?("", "")
    end

    test "base_id prefers an explicit id and sanitizes a field name otherwise" do
      assert Options.base_id("given", "filters[company]") == "given"
      assert Options.base_id(nil, "filters[company]") == "filters-company-"
    end

    test "display_of resolves through groups and returns nil for a blank value" do
      groups = [
        %{label: "AADB", options: [%{label: "admin", value: "1", display: "AADB - admin"}]}
      ]

      assert Options.display_of(groups, "1") == "AADB - admin"
      assert Options.display_of(groups, "9") == nil
      assert Options.display_of(groups, nil) == nil
    end
  end

  describe "grouping and matching" do
    test "detects groups and flattens leaves" do
      groups = [
        {"AADB", [{"admin", "1"}]},
        %{label: "Realm", options: [%{label: "owner", value: "3"}]}
      ]

      assert Options.grouped?(groups)
      refute Options.grouped?([{"Alpha", "1"}])
      assert Options.group_label({"AADB", [{"admin", "1"}]}) == "AADB"
      assert Options.leaf_options(groups) == [{"admin", "1"}, %{label: "owner", value: "3"}]
      assert Options.leaf_options([{"Alpha", "1"}]) == [{"Alpha", "1"}]
    end

    test "a disabled group disables every option in it, promoting tuples to maps" do
      group = %{
        label: "Legacy",
        options: [{"admin", "1"}, %{label: "owner", value: "3"}],
        disabled: true
      }

      assert Options.group_disabled?(group)
      refute Options.group_disabled?(%{label: "Legacy", options: []})
      refute Options.group_disabled?({"Legacy", [{"admin", "1"}]})

      assert Options.group_leaves(group) == [
               %{label: "admin", value: "1", disabled: true},
               %{label: "owner", value: "3", disabled: true}
             ]

      # group_options stays a plain accessor, so the two are not interchangeable
      assert Options.group_options(group) == [{"admin", "1"}, %{label: "owner", value: "3"}]
    end

    test "an option keeps its own keys when a disabled group promotes it" do
      group = %{
        label: "Legacy",
        disabled: true,
        options: [%{label: "owner", value: "3", badge: 0, disabled_reason: "Nobody holds this"}]
      }

      assert [item] = Options.group_leaves(group)
      assert Options.item_disabled(item)
      assert Options.item_disabled_reason(item) == "Nobody holds this"
      assert Options.item_badge(item) == "0"
    end

    test "leaf_options and find_option carry a group's disabling down to its options" do
      groups = [
        %{label: "Live", options: [{"admin", "1"}]},
        %{label: "Legacy", options: [{"owner", "3"}], disabled: true}
      ]

      assert Options.leaf_options(groups) == [
               {"admin", "1"},
               %{label: "owner", value: "3", disabled: true}
             ]

      assert groups |> Options.find_option("3") |> Options.item_disabled()
      refute groups |> Options.find_option("1") |> Options.item_disabled()
      assert Options.display_of(groups, "3") == "owner"
    end

    test "matches on the search text, case-insensitively, and passes everything through for a blank term" do
      options = [%{label: "Alpha AG", value: "1", search: "Alpha AG zurich"}, {"Beta AG", "2"}]

      assert Options.matches(options, "ZURICH") == [Enum.at(options, 0)]
      assert Options.matches(options, "beta") == [{"Beta AG", "2"}]
      assert Options.matches(options, "") == options
      assert Options.matches(options, nil) == options
    end
  end

  describe "dropdown_groups/4 without a cap" do
    test "returns every option and never reports more" do
      {groups, visible, has_more?} = Options.dropdown_groups(flat(30), "", nil, none())

      assert [%{label: nil, options: options}] = groups
      assert length(options) == 30
      assert length(visible) == 30
      refute has_more?
    end
  end

  describe "dropdown_groups/4 flat" do
    test "caps at max_results and reports more" do
      {_groups, visible, has_more?} = Options.dropdown_groups(flat(12), "", 10, none())

      assert length(visible) == 10
      assert has_more?
    end

    test "keeps natural order when every selection is already visible" do
      {_groups, visible, _more} = Options.dropdown_groups(flat(12), "", 10, selects(["2"]))

      assert visible |> Enum.map(&Options.item_value(&1)) |> Enum.take(3) == ["1", "2", "3"]
    end

    test "pins a selection that falls past the cap, dropping the last visible option" do
      {_groups, visible, _more} = Options.dropdown_groups(flat(12), "", 10, selects(["12"]))

      values = Enum.map(visible, &Options.item_value/1)
      assert hd(values) == "12"
      assert length(values) == 10
      refute "10" in values
    end

    test "pins every selection that falls past the cap" do
      {_groups, visible, _more} = Options.dropdown_groups(flat(20), "", 10, selects(["18", "20"]))

      values = Enum.map(visible, &Options.item_value/1)
      assert Enum.take(values, 2) == ["18", "20"]
      assert length(values) == 10
    end

    test "renders every selection even when the selection alone exceeds the cap" do
      selected = ["5", "10", "15", "20"]
      {_groups, visible, _more} = Options.dropdown_groups(flat(20), "", 3, selects(selected))

      values = Enum.map(visible, &Options.item_value/1)

      assert values == selected
      assert length(values) > 3
    end

    test "spends what is left of the cap on unselected options" do
      {_groups, visible, _more} = Options.dropdown_groups(flat(20), "", 3, selects(["18", "20"]))

      values = Enum.map(visible, &Options.item_value/1)

      assert Enum.take(values, 2) == ["18", "20"]
      assert length(values) == 3
    end

    test "reports more against what is actually on screen, not the raw cap" do
      {_groups, _visible, has_more?} =
        Options.dropdown_groups(flat(4), "", 3, selects(["1", "2", "3", "4"]))

      refute has_more?
    end
  end

  describe "dropdown_groups/4 with disabled options" do
    test "disabled options do not spend the cap" do
      options = [off({"a", "1"}), off({"b", "2"}), {"c", "3"}, {"d", "4"}]

      {_groups, visible, has_more?} = Options.dropdown_groups(options, "", 2, none())

      assert values_of(visible) == ["1", "2", "3", "4"]
      refute has_more?
    end

    test "the window still closes on the cap-th enabled option, dropping what follows" do
      options = [{"a", "1"}, {"b", "2"}, off({"c", "3"}), {"d", "4"}]

      {_groups, visible, has_more?} = Options.dropdown_groups(options, "", 2, none())

      assert values_of(visible) == ["1", "2"]
      assert has_more?
    end

    test "disabled options dropped past the cap do not raise the more hint" do
      options = [{"a", "1"}, {"b", "2"}, off({"c", "3"}), off({"d", "4"})]

      {_groups, visible, has_more?} = Options.dropdown_groups(options, "", 2, none())

      assert values_of(visible) == ["1", "2"]
      refute has_more?
    end

    test "a run of disabled options can never squeeze the enabled ones out of view" do
      disabled = Enum.map(1..20, &off({"d#{&1}", "d#{&1}"}))
      options = disabled ++ [{"e1", "e1"}, {"e2", "e2"}, {"e3", "e3"}]

      {_groups, visible, has_more?} = Options.dropdown_groups(options, "", 2, none())
      values = values_of(visible)

      assert Enum.filter(values, &String.starts_with?(&1, "e")) == ["e1", "e2"]
      assert length(values) == 22
      assert has_more?
    end

    test "renders every match when the list holds fewer enabled options than the cap" do
      options = Enum.map(1..5, &off({"d#{&1}", "d#{&1}"}))

      {_groups, visible, has_more?} = Options.dropdown_groups(options, "", 2, none())

      assert length(visible) == 5
      refute has_more?
    end

    test "a disabled selection is pinned into view without costing a slot" do
      options = flat(11) ++ [off({"opt-12", "12"})]

      {_groups, visible, _more} = Options.dropdown_groups(options, "", 10, selects(["12"]))
      values = values_of(visible)

      assert hd(values) == "12"
      # the enabled equivalent drops "10" to make room; this one does not
      assert "10" in values
      assert length(values) == 11
    end

    test "disabled options are still filtered by the search term" do
      options = [off({"Alpha", "1"}), {"Beta", "2"}]

      {_groups, visible, _more} = Options.dropdown_groups(options, "alpha", nil, none())

      assert values_of(visible) == ["1"]
    end

    test "a disabled group renders its options without spending the cap" do
      options = [
        %{label: "Legacy", options: [{"a1", "a1"}, {"a2", "a2"}], disabled: true},
        %{label: "Live", options: for(i <- 1..8, do: {"b#{i}", "b#{i}"})}
      ]

      {groups, visible, has_more?} = Options.dropdown_groups(options, "", 3, none())

      assert Enum.map(groups, & &1.label) == ["Legacy", "Live"]
      assert values_of(visible) == ["a1", "a2", "b1", "b2", "b3"]
      assert Enum.all?(Enum.at(groups, 0).options, &Options.item_disabled/1)
      assert has_more?
    end

    test "a disabled selection in a later group reserves nothing, since it costs nothing" do
      options = [
        %{label: "A", options: for(i <- 1..8, do: {"a#{i}", "a#{i}"})},
        %{label: "B", options: [{"b1", "b1"}, off({"b2", "b2"})]}
      ]

      {groups, _visible, _more} = Options.dropdown_groups(options, "", 8, selects(["b2"]))

      assert values_of(Enum.at(groups, 0).options) == ~w[a1 a2 a3 a4 a5 a6 a7 a8]
      assert values_of(Enum.at(groups, 1).options) == ["b2"]
    end
  end

  describe "dropdown_groups/4 grouped" do
    setup do
      %{
        options: [
          %{label: "A", options: for(i <- 1..8, do: %{label: "a#{i}", value: "a#{i}"})},
          %{label: "B", options: for(i <- 1..8, do: %{label: "b#{i}", value: "b#{i}"})}
        ]
      }
    end

    test "spends the cap in group order and reports more", %{options: options} do
      {groups, visible, has_more?} = Options.dropdown_groups(options, "", 10, none())

      assert Enum.map(groups, & &1.label) == ["A", "B"]
      assert length(visible) == 10
      assert Enum.map(Enum.at(groups, 1).options, &Options.item_value/1) == ["b1", "b2"]
      assert has_more?
    end

    test "reserves a slot so a later group's selection stays visible", %{options: options} do
      {groups, _visible, _more} = Options.dropdown_groups(options, "", 10, selects(["b7"]))

      assert Enum.map(groups, & &1.label) == ["A", "B"]
      assert Enum.map(Enum.at(groups, 1).options, &Options.item_value/1) == ["b7", "b1"]
    end

    test "reserves one slot per selection across groups", %{options: options} do
      {groups, _visible, _more} = Options.dropdown_groups(options, "", 10, selects(["b7", "b8"]))

      assert Enum.map(Enum.at(groups, 1).options, &Options.item_value/1) == ["b7", "b8"]
      assert length(Enum.at(groups, 0).options) == 8
    end

    test "renders every selection across groups when they outnumber the cap", %{options: options} do
      selected = ["a2", "a5", "b3", "b7"]
      {groups, visible, _more} = Options.dropdown_groups(options, "", 3, selects(selected))

      assert Enum.map(groups, & &1.label) == ["A", "B"]
      assert Enum.map(visible, &Options.item_value/1) == selected
    end

    test "drops groups that match nothing", %{options: options} do
      {groups, _visible, _more} = Options.dropdown_groups(options, "b3", 10, none())

      assert Enum.map(groups, & &1.label) == ["B"]
    end

    test "keeps natural order within a group that isn't truncated" do
      options = [
        %{
          label: "G",
          options: [
            %{label: "a", value: "a"},
            %{label: "b", value: "b"},
            %{label: "c", value: "c"}
          ]
        }
      ]

      {groups, _visible, _more} = Options.dropdown_groups(options, "", 15, selects(["c"]))

      assert Enum.map(Enum.at(groups, 0).options, &Options.item_value/1) == ["a", "b", "c"]
    end

    test "keeps every selection that fits, never dropping one for an unselected option" do
      options = [
        %{
          label: "G",
          options: [
            %{label: "a", value: "a"},
            %{label: "b", value: "b"},
            %{label: "c", value: "c"},
            %{label: "d", value: "d"},
            %{label: "e", value: "e"}
          ]
        }
      ]

      {groups, _visible, _more} = Options.dropdown_groups(options, "", 2, selects(["b", "d"]))

      assert Enum.map(Enum.at(groups, 0).options, &Options.item_value/1) == ["b", "d"]
    end
  end
end
