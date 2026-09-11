defmodule MyAppWeb.Components.Cinder.Filters.MultiSelectTest do
  @moduledoc false
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias MyAppWeb.Components.Cinder.Filters.MultiSelect

  defp render(current_value, assigns, filter_options \\ [options: [{"Acme AG", "1"}, {"Beta AG", "2"}]]) do
    column = %{field: "role", label: "Role", filter_options: filter_options}

    column
    |> MultiSelect.render(current_value, %{}, assigns)
    |> rendered_to_string()
  end

  test "renders checkboxes under Cinder's array param name" do
    html = render(["1"], %{table_id: "users", raw_filter_params: %{}})

    assert html =~ ~s(name="filters[role][]")
    assert html =~ ~s(type="checkbox")
    assert html =~ ~s(value="1" checked)
    assert html =~ "Acme AG"
  end

  test "uses the prompt as the accessible name and summarises the selection" do
    html =
      render(["1", "2"], %{table_id: "users", raw_filter_params: %{}},
        options: [{"Acme AG", "1"}, {"Beta AG", "2"}],
        prompt: "All roles"
      )

    assert html =~ ~s(aria-label="All roles")
    assert html =~ ~s(placeholder="2 selected")
  end

  test "wires Clear all to Cinder's clear_filter" do
    selected = render(["1"], %{table_id: "users", raw_filter_params: %{}, target: "#users"})

    {:ok, doc} = Floki.parse_fragment(selected)
    button = Floki.find(doc, ".combobox-actions button")

    assert Floki.text(button) =~ "Clear all"
    assert Floki.attribute(button, "phx-click") == ["clear_filter"]
    assert Floki.attribute(button, "phx-value-key") == ["role"]
    assert Floki.attribute(button, "phx-target") == ["#users"]
    assert Floki.attribute(button, "data-clears-search") == ["true"]
    assert Floki.attribute(button, "disabled") == []
  end

  test "keeps the actions row in place with nothing selected, disabling only Clear all" do
    empty = render([], %{table_id: "users", raw_filter_params: %{}, target: "#users"})

    {:ok, doc} = Floki.parse_fragment(empty)

    assert Floki.find(doc, ".combobox-actions") != []

    assert doc |> Floki.find(".combobox-actions button") |> Floki.attribute("disabled") ==
             ["disabled"]

    assert doc
           |> Floki.find(~s(.combobox-actions input[type="checkbox"]))
           |> Floki.attribute("disabled") == []
  end

  test "names the listbox from the prompt, since the filters carry no visible label" do
    html =
      render(["1"], %{table_id: "users", raw_filter_params: %{}},
        options: [{"Acme AG", "1"}],
        prompt: "All roles"
      )

    {:ok, doc} = Floki.parse_fragment(html)

    assert doc |> Floki.find(~s([role="listbox"])) |> Floki.attribute("aria-label") == [
             "All roles"
           ]
  end

  test "reflects the stored search term" do
    real =
      render([], %{table_id: "users", raw_filter_params: %{"role_autocomplete_search" => "beta"}})

    assert real =~ "Beta AG"
    refute real =~ "Acme AG"
  end

  test "keeps filtering while the selection grows, since the term is never the summary" do
    params = %{"role_autocomplete_search" => "beta"}
    html = render(["1", "2"], %{table_id: "users", raw_filter_params: params})

    assert html =~ ~s(value="beta")
    assert html =~ ~s(placeholder="2 selected")
    assert html =~ ~s(id="users-filter-role-dropdown-opt-2")
    refute html =~ ~s(id="users-filter-role-dropdown-opt-1")
    assert html =~ ~s(type="hidden" name="filters[role][]" value="1")
  end

  test "renders the match-mode toggle, reflecting the sentinel, and keeps it out of the selection" do
    any = render(["1"], %{table_id: "users", raw_filter_params: %{}, target: "#users"})

    all =
      render(["~mode:all", "1"], %{table_id: "users", raw_filter_params: %{}, target: "#users"})

    {:ok, any_doc} = Floki.parse_fragment(any)
    {:ok, all_doc} = Floki.parse_fragment(all)

    toggle = fn doc -> Floki.find(doc, ~s(.combobox-actions input[value="~mode:all"])) end

    assert Floki.attribute(toggle.(any_doc), "name") == ["filters[role][]"]
    assert Floki.attribute(toggle.(any_doc), "checked") == []
    assert Floki.attribute(toggle.(all_doc), "checked") == ["checked"]

    refute all =~ ~s(id="users-filter-role-dropdown-opt-~mode:all")
    assert all =~ ~s(placeholder="Acme AG")
  end

  test "only spells out :any when the column defaults to :all, keeping URLs clean otherwise" do
    default_any = render(["1"], %{table_id: "users", raw_filter_params: %{}, target: "#users"})

    default_all =
      render(["1"], %{table_id: "users", raw_filter_params: %{}, target: "#users"},
        options: [{"Acme AG", "1"}],
        match_mode: :all
      )

    {:ok, any_doc} = Floki.parse_fragment(default_any)
    {:ok, all_doc} = Floki.parse_fragment(default_all)

    assert Floki.find(any_doc, ~s(.combobox-actions input[type="hidden"])) == []

    assert all_doc
           |> Floki.find(~s(.combobox-actions input[type="hidden"]))
           |> Floki.attribute("value") == ["~mode:any"]

    assert all_doc
           |> Floki.find(~s(.combobox-actions input[type="checkbox"]))
           |> Floki.attribute("checked") == ["checked"]
  end

  test "process/2 carries the mode in the value so it survives Cinder's URL round-trip" do
    assert MultiSelect.process(["~mode:all", "1", "2"], %{}) == %{
             type: :multi_select,
             value: ["~mode:all", "1", "2"],
             operator: :in,
             match_mode: :all
           }

    assert %{match_mode: :any} = MultiSelect.process(["~mode:any", "1"], %{})
    assert %{match_mode: :all} = MultiSelect.process(["~mode:any", "~mode:all", "1"], %{})
  end

  test "a mode sentinel on its own is not a filter" do
    assert MultiSelect.process(["~mode:all"], %{}) == nil
    assert MultiSelect.process(["~mode:any", ""], %{}) == nil

    assert MultiSelect.empty?(%{value: ["~mode:all"]})
    refute MultiSelect.empty?(%{value: ["~mode:all", "1"]})
    refute MultiSelect.validate(%{type: :multi_select, value: ["~mode:all"], operator: :in})
  end

  test "process/2 matches the built-in :multi_select shape" do
    assert MultiSelect.process(["1", "2"], %{}) == %{
             type: :multi_select,
             value: ["1", "2"],
             operator: :in,
             match_mode: :any
           }

    assert MultiSelect.process(["", nil], %{}) == nil
    assert MultiSelect.process([], %{}) == nil
  end

  test "process/2 wraps a lone binary in a list rather than splitting it" do
    assert MultiSelect.process("1,2", %{}) == %{
             type: :multi_select,
             value: ["1,2"],
             operator: :in,
             match_mode: :any
           }
  end

  test "process/2 honours match_mode from the column, and lets the toggle override it" do
    column = %{filter_options: [match_mode: :all]}

    assert %{match_mode: :all} = MultiSelect.process(["1"], column)
    assert %{match_mode: :any} = MultiSelect.process(["~mode:any", "1"], column)
    assert %{match_mode: :all} = MultiSelect.process(["~mode:any", "~mode:all", "1"], column)
  end

  test "process/2 drops values the column's options do not offer, keeping the mode sentinel" do
    column = %{
      filter_options: [
        options: [{"Acme AG", "1"}, %{label: "Beta AG", value: "2", disabled: true}]
      ]
    }

    assert MultiSelect.process(["~mode:all", "1", "2", "9"], column) == %{
             type: :multi_select,
             value: ["~mode:all", "1"],
             operator: :in,
             match_mode: :all
           }

    # nothing selectable left is the same as nothing selected
    assert MultiSelect.process(["2", "9"], column) == nil
  end

  test "validate/1 accepts both the match_mode and legacy shapes" do
    assert MultiSelect.validate(%{
             type: :multi_select,
             value: ["1"],
             operator: :in,
             match_mode: :any
           })

    assert MultiSelect.validate(%{type: :multi_select, value: ["1"], operator: :in})
    refute MultiSelect.validate(%{type: :multi_select, value: [], operator: :in})

    refute MultiSelect.validate(%{
             type: :multi_select,
             value: ["1"],
             operator: :in,
             match_mode: :some
           })

    refute MultiSelect.validate(%{type: :select, value: ["1"], operator: :in})
  end

  test "empty? covers every blank shape" do
    assert MultiSelect.empty?(nil)
    assert MultiSelect.empty?([])
    assert MultiSelect.empty?(%{value: []})
    assert MultiSelect.empty?(%{value: nil})
    refute MultiSelect.empty?(%{value: ["1"]})
  end

  test "default_options declares what the wrapper reads" do
    options = MultiSelect.default_options()

    assert options[:match_mode] == :any
    assert options[:options] == []
    assert options[:prompt] == nil
  end
end
