defmodule MyAppWeb.Components.Core.Inputs.ComboboxTest do
  @moduledoc false
  use MyAppWeb.ConnCase, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias MyAppWeb.Components.Core.Inputs.Combobox

  @options [{"Alpha — Alpha AG", "1"}, {"Beta — Beta AG", "2"}]

  defp render_combobox(overrides) do
    assigns =
      Keyword.merge(
        [field: "to_id", label: "Company", search_name: "counterpart_search", options: @options],
        overrides
      )

    render_component(&Combobox.combobox/1, assigns)
  end

  defp hidden_fallback(html) do
    {:ok, doc} = Floki.parse_fragment(html)

    doc |> Floki.find(~s(input[type="hidden"])) |> Enum.at(0)
  end

  test "renders a radio per option under the field's name" do
    html = render_combobox([])

    assert html =~ ~s(type="radio")
    assert html =~ ~s(name="to_id")
    assert html =~ "Alpha — Alpha AG"
    assert html =~ "Beta — Beta AG"
  end

  test "renders the search input under the search name" do
    html = render_combobox(placeholder: "Search companies…")

    assert html =~ ~s(name="counterpart_search")
    assert html =~ ~s(placeholder="Search companies…")
  end

  test "wires the search input to its own event when search_event is given" do
    assert render_combobox(search_event: "relation:search") =~
             ~s(phx-change="relation:search")

    refute render_combobox([]) =~ "phx-change"
  end

  test "filters options case-insensitively by the search term" do
    html = render_combobox(search_term: "ALPHA")

    assert html =~ "Alpha — Alpha AG"
    refute html =~ "Beta — Beta AG"
  end

  test "shows the empty row when nothing matches" do
    html = render_combobox(search_term: "zzz")

    assert html =~ "No results found"
  end

  test "caps the dropdown at max_results and hints at more" do
    options = for i <- 1..12, do: {"opt-#{String.pad_leading("#{i}", 2, "0")}", "#{i}"}
    html = render_combobox(options: options)

    assert html =~ "opt-10"
    refute html =~ "opt-11"
    assert html =~ "Type to search more options…"
  end

  test "checks the selected option and shows its label in the search input" do
    html = render_combobox(value: "2")

    assert html =~ ~s(value="2" checked)
    assert html =~ ~s(value="Beta — Beta AG")
  end

  test "exposes the selected label even when the option is filtered out" do
    html = render_combobox(value: "2", search_term: "Alpha")

    assert html =~ ~s(data-selected-label="Beta — Beta AG")
  end

  test "the hidden fallback carries the value only when the selection is filtered out" do
    filtered_out = render_combobox(value: "2", search_term: "Alpha")
    visible = render_combobox(value: "2", search_term: "Beta")

    assert filtered_out =~ ~s(type="hidden" name="to_id" value="2")
    refute filtered_out =~ ~s(value="2" disabled)
    assert visible =~ ~s(type="hidden" name="to_id" value="2" disabled)
  end

  test "wraps the hidden fallback so its appearance cannot shift the trigger" do
    {:ok, doc} = Floki.parse_fragment(render_combobox(value: "2", search_term: "Alpha"))
    wrapper = Floki.find(doc, "div.contents")

    assert wrapper |> Floki.find(~s(input[type="hidden"])) |> Floki.attribute("value") == ["2"]
    assert Floki.find(wrapper, ~s([role="combobox"])) == []
  end

  describe "disabled options" do
    @mixed [
      {"Alpha — Alpha AG", "1"},
      %{label: "Beta — Beta AG", value: "2", disabled: true}
    ]

    test "renders the option greyed and inert" do
      html = render_combobox(options: @mixed)

      assert html =~ ~s(data-disabled="true")
      assert html =~ ~s(value="2" disabled)
    end

    test "the hidden fallback carries a disabled selection, visible or not" do
      # the radio is on screen but disabled, so it would submit nothing on its own
      visible = hidden_fallback(render_combobox(options: @mixed, value: "2", search_term: "Beta"))
      away = hidden_fallback(render_combobox(options: @mixed, value: "2", search_term: "Alpha"))

      assert Floki.attribute([visible], "value") == ["2"]
      assert Floki.attribute([visible], "disabled") == []
      assert Floki.attribute([away], "value") == ["2"]
      assert Floki.attribute([away], "disabled") == []
    end

    test "still disables the fallback for an ordinary visible selection" do
      fallback =
        hidden_fallback(render_combobox(options: @mixed, value: "1", search_term: "Alpha"))

      assert Floki.attribute([fallback], "value") == ["1"]
      assert Floki.attribute([fallback], "disabled") == ["disabled"]
    end

    test "keeps a disabled selection in the trigger, which disabling must never hide" do
      html = render_combobox(options: @mixed, value: "2")

      assert html =~ ~s(data-selected-label="Beta — Beta AG")
    end

    test "disables every option of a disabled group, and carries a selection from it" do
      options = [
        %{label: "Live", options: [{"Alpha — Alpha AG", "1"}]},
        %{label: "Legacy", options: [{"Beta — Beta AG", "2"}], disabled: true}
      ]

      html = render_combobox(options: options, value: "2")
      {:ok, doc} = Floki.parse_fragment(html)

      assert doc |> Floki.find("#to_id-dropdown-opt-2") |> Floki.attribute("data-disabled") ==
               ["true"]

      assert doc |> Floki.find("#to_id-dropdown-opt-1") |> Floki.attribute("data-disabled") == []
      assert Floki.attribute([hidden_fallback(html)], "disabled") == []
    end
  end

  test "exposes the ARIA combobox pattern" do
    html = render_combobox(value: "2")

    assert html =~ ~s(role="combobox")
    assert html =~ ~s(aria-autocomplete="list")
    assert html =~ ~s(aria-haspopup="listbox")
    assert html =~ ~s(aria-expanded="false")
    assert html =~ ~s(aria-controls="to_id-dropdown")
    assert html =~ ~s(role="listbox")
    assert html =~ ~s(role="option")
    assert html =~ ~s(id="to_id-dropdown-opt-2")
  end

  test "renders a tabindex=-1 toggle button wired to the listbox" do
    html = render_combobox(value: "2")

    assert html =~ ~s(id="to_id-button")
    assert html =~ ~s(tabindex="-1")
    assert html =~ ~s(aria-controls="to_id-dropdown")
    assert html =~ ~s(aria-expanded="false")
  end

  test "leaves aria-selected and aria-activedescendant to the hook (absent at rest)" do
    html = render_combobox(value: "2")

    refute html =~ "aria-selected"
    refute html =~ "aria-activedescendant"
  end

  test "marks the committed value with a check in the list" do
    assert render_combobox(value: "2") =~ "✓"
    refute render_combobox(value: nil) =~ "✓"
  end

  test "renders the dropdown as an anchor-positioned popover" do
    html = render_combobox([])

    assert html =~ ~s(popover="manual")
    assert html =~ "anchor-name: --to_id-anchor"
    assert html =~ "position-anchor: --to_id-anchor"
  end

  test "omits the blank option unless allow_blank is set" do
    refute render_combobox([]) =~ "-opt-blank"
  end

  test "renders a checked blank option when allow_blank and no value" do
    html = render_combobox(allow_blank: true, blank_label: "Any", value: nil)

    assert html =~ ~s(id="to_id-dropdown-opt-blank")
    assert html =~ "Any"
    assert html =~ ~s(type="radio" name="to_id" value="" checked)
    refute html =~ ~s(name="to_id" value="1" checked)
  end

  test "leaves the blank option unchecked when a value is selected" do
    html = render_combobox(allow_blank: true, value: "2")

    assert html =~ ~s(type="radio" name="to_id" value="")
    refute html =~ ~s(name="to_id" value="" checked)
    assert html =~ ~s(value="2" checked)
  end

  test "derives element ids from the field name when no id is given" do
    html = render_combobox([])

    assert html =~ ~s(id="to_id-combobox")
    assert html =~ ~s(id="to_id-dropdown")
  end

  test "does not treat a blank value as matching a blank option" do
    html = render_combobox(options: [{"None", ""}, {"Beta — Beta AG", "2"}], value: "")

    refute html =~ "✓"
    refute html =~ "checked"
    refute html =~ ~s(type="hidden")
  end

  test "keeps natural order when the selected option is already visible" do
    html = render_combobox(value: "2")

    assert html =~ ~r/Alpha — Alpha AG[\s\S]*Beta — Beta AG/
  end

  test "pins the selected option into view when it falls outside max_results" do
    options = for i <- 1..12, do: {"opt-#{String.pad_leading("#{i}", 2, "0")}", "#{i}"}
    html = render_combobox(options: options, value: "12")

    assert html =~ "opt-12"
    assert html =~ ~s(value="12" checked)
    refute html =~ "opt-10"
  end

  test "accepts map options, keying the radio and label off :value and :label" do
    html =
      render_combobox(
        options: [%{label: "Alpha AG", value: "1"}, %{label: "Beta AG", value: "2"}],
        value: "2"
      )

    assert html =~ ~s(name="to_id" value="2" checked)
    assert html =~ ~s(value="Beta AG")
    assert html =~ ~s(id="to_id-dropdown-opt-2")
  end

  test "matches a map's :search field without changing the displayed label" do
    options = [
      %{label: "Alpha AG", value: "1", search: "Alpha AG ALP zurich"},
      %{label: "Beta AG", value: "2", search: "Beta AG BET bern"}
    ]

    by_short = render_combobox(options: options, search_term: "alp")
    assert by_short =~ "Alpha AG"
    refute by_short =~ "Beta AG"

    by_city = render_combobox(options: options, search_term: "bern")
    assert by_city =~ "Beta AG"
    refute by_city =~ "Alpha AG"
  end

  test "renders grouped options as labelled listbox groups" do
    options = [
      %{label: "AADB", options: [%{label: "admin", value: "1"}, %{label: "viewer", value: "2"}]},
      %{label: "Realm", options: [%{label: "owner", value: "3"}]}
    ]

    html = render_combobox(options: options, value: "3")

    assert html =~ ~s(role="group")
    assert html =~ ~s(id="to_id-dropdown-group-0")
    assert html =~ ~s(aria-labelledby="to_id-dropdown-group-0")
    assert html =~ ~s(id="to_id-dropdown-group-1")
    assert html =~ "AADB"
    assert html =~ ~s(id="to_id-dropdown-opt-1")
    assert html =~ ~s(id="to_id-dropdown-opt-3")
    assert html =~ ~s(value="3" checked)
  end

  test "caps grouped options at max_results across groups and hints at more" do
    options = [
      %{label: "A", options: for(i <- 1..8, do: %{label: "a#{i}", value: "a#{i}"})},
      %{label: "B", options: for(i <- 1..8, do: %{label: "b#{i}", value: "b#{i}"})}
    ]

    html = render_combobox(options: options, max_results: 10)

    # 10 shown across the two groups: all of A, then b1..b2
    assert html =~ ~s(id="to_id-dropdown-opt-a8")
    assert html =~ ~s(id="to_id-dropdown-opt-b2")
    refute html =~ ~s(id="to_id-dropdown-opt-b3")
    assert html =~ "Type to search more options…"
  end

  test "pins the selected option into its own group when it falls outside max_results" do
    options = [
      %{label: "A", options: for(i <- 1..8, do: %{label: "a#{i}", value: "a#{i}"})},
      %{label: "B", options: for(i <- 1..8, do: %{label: "b#{i}", value: "b#{i}"})}
    ]

    html = render_combobox(options: options, max_results: 10, value: "b7")

    # b7 takes the first of group B's two slots, displacing b2; group order is kept.
    assert html =~ ~s(id="to_id-dropdown-opt-b7")
    assert html =~ ~s(value="b7" checked)
    assert html =~ ~s(id="to_id-dropdown-opt-b1")
    refute html =~ ~s(id="to_id-dropdown-opt-b2")
    assert html =~ ~r/id="to_id-dropdown-group-0"[\s\S]*id="to_id-dropdown-opt-b7"/
  end

  test "pins the selected option when its group falls outside max_results entirely" do
    options = [
      %{label: "A", options: for(i <- 1..10, do: %{label: "a#{i}", value: "a#{i}"})},
      %{label: "B", options: for(i <- 1..8, do: %{label: "b#{i}", value: "b#{i}"})}
    ]

    html = render_combobox(options: options, max_results: 10, value: "b3")

    assert html =~ ~s(id="to_id-dropdown-opt-b3")
    assert html =~ ~s(id="to_id-dropdown-group-1")
    refute html =~ ~s(id="to_id-dropdown-opt-b4")
    refute html =~ ~s(id="to_id-dropdown-opt-a10")
  end

  test "filters within groups, matches a leaf's :search, and drops empty groups" do
    options = [
      %{label: "AADB", options: [%{label: "admin", value: "1", search: "AADB admin"}]},
      %{label: "Realm", options: [%{label: "owner", value: "3", search: "Realm owner"}]}
    ]

    by_app = render_combobox(options: options, search_term: "aadb")
    assert by_app =~ ~s(data-label="admin")
    refute by_app =~ ~s(data-label="owner")
    refute by_app =~ ~s(id="to_id-dropdown-group-1")

    by_leaf = render_combobox(options: options, search_term: "owner")
    assert by_leaf =~ ~s(data-label="owner")
    refute by_leaf =~ ~s(data-label="admin")
    refute by_leaf =~ ~s(id="to_id-dropdown-group-1")
  end

  test "uses :display in the input while the row keeps the short label" do
    options = [
      %{label: "AADB", options: [%{label: "admin", value: "1", display: "AADB - admin"}]}
    ]

    html = render_combobox(options: options, value: "1")

    assert html =~ ~s(value="AADB - admin")
    assert html =~ ~s(data-selected-label="AADB - admin")
    assert html =~ ~s(data-label="AADB - admin")
    assert html =~ ~s(select-none text-sm">admin</span>)
  end

  test "renders each row through the :option slot with label/value/selected" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Combobox.combobox
        field="to_id"
        label="Company"
        search_name="counterpart_search"
        value="2"
        options={[%{label: "Alpha AG", value: "1"}, %{label: "Beta AG", value: "2"}]}
      >
        <:option :let={opt}>
          <span data-row={opt.value} data-selected={to_string(opt.selected)}>{opt.label}</span>
        </:option>
      </Combobox.combobox>
      """)

    assert html =~ ~s(data-row="1" data-selected="false")
    assert html =~ ~s(data-row="2" data-selected="true")
    refute html =~ "✓"
  end
end
