defmodule MyAppWeb.Components.Core.Inputs.MultiSelectTest do
  @moduledoc false
  use MyAppWeb.ConnCase, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias MyAppWeb.Components.Core.Inputs.MultiSelect

  @options [{"Alpha AG", "1"}, {"Beta AG", "2"}, {"Gamma AG", "3"}]

  defp render_multi(overrides) do
    assigns =
      Keyword.merge(
        [field: "filters[role]", label: "Role", search_name: "role_search", options: @options],
        overrides
      )

    render_component(&MultiSelect.multi_select/1, assigns)
  end

  test "renders a checkbox per option under the array field name" do
    html = render_multi([])

    assert html =~ ~s(type="checkbox" name="filters[role][]")
    assert html =~ "Alpha AG"
    assert html =~ "Gamma AG"
  end

  test "checks every selected option" do
    html = render_multi(value: ["1", "3"])

    assert html =~ ~s(value="1" checked)
    assert html =~ ~s(value="3" checked)
    refute html =~ ~s(value="2" checked)
  end

  test "always renders the empty sentinel so clearing every box still submits the field" do
    assert render_multi([]) =~ ~s(type="hidden" name="filters[role][]" value="")
    assert render_multi(value: ["1"]) =~ ~s(type="hidden" name="filters[role][]" value="")
  end

  test "summarises the selection in the trigger placeholder" do
    assert render_multi(value: [], placeholder: "Search roles…") =~
             ~s(placeholder="Search roles…")

    assert render_multi(value: ["2"]) =~ ~s(placeholder="Beta AG")
    assert render_multi(value: ["1", "2"]) =~ ~s(placeholder="2 selected")
    assert render_multi(value: ["1", "2", "3"]) =~ ~s(placeholder="3 selected")
  end

  test "keeps the trigger value the search term alone, never the summary" do
    html = render_multi(value: ["1", "2"], search_term: "Alpha")

    assert html =~ ~s(value="Alpha")
    refute html =~ ~s(value="2 selected")
    refute html =~ ~s(value="Beta AG")
  end

  test "renders the summary like input text and the placeholder muted" do
    assert render_multi(value: ["1", "2"]) =~ "placeholder:text-base-content"

    refute render_multi(value: [], placeholder: "Search roles…") =~
             "placeholder:text-base-content"
  end

  test "never styles the summary as a text selection, since the value is empty" do
    refute render_multi(value: ["1", "2"]) =~ "Highlight"
  end

  test "carries a selected value that the search term hides, and only then" do
    hidden = render_multi(value: ["3"], search_term: "Alpha")
    visible = render_multi(value: ["3"], search_term: "Gamma")

    assert hidden =~ ~s(type="hidden" name="filters[role][]" value="3")
    refute hidden =~ ~s(value="3" checked)

    refute visible =~ ~s(type="hidden" name="filters[role][]" value="3")
    assert visible =~ ~s(value="3" checked)
  end

  test "carries only the hidden ones when the selection is split" do
    html = render_multi(value: ["1", "3"], search_term: "Alpha")

    assert html =~ ~s(value="1" checked)
    assert html =~ ~s(type="hidden" name="filters[role][]" value="3")
    refute html =~ ~s(type="hidden" name="filters[role][]" value="1")
  end

  test "wraps the hidden inputs so their changing count cannot shift the trigger" do
    {:ok, doc} = Floki.parse_fragment(render_multi(value: ["1", "3"], search_term: "Alpha"))
    wrapper = Floki.find(doc, "div.contents")

    assert wrapper |> Floki.find(~s(input[type="hidden"])) |> Floki.attribute("value") == [
             "",
             "3"
           ]

    assert Floki.find(wrapper, ~s([role="combobox"])) == []
  end

  test "announces the summary through a hidden description the trigger points at" do
    {:ok, doc} = Floki.parse_fragment(render_multi(value: ["1", "2"]))

    assert doc |> Floki.find("#filters-role--summary") |> Floki.text() == "2 selected"

    assert doc |> Floki.find(~s([role="combobox"])) |> Floki.attribute("aria-describedby") ==
             ["filters-role--summary"]
  end

  test "renders the description target even with nothing selected, so it never shifts siblings" do
    {:ok, doc} = Floki.parse_fragment(render_multi(value: []))

    assert doc |> Floki.find("#filters-role--summary") |> Floki.text() == ""
    assert doc |> Floki.find(~s([role="combobox"])) |> Floki.attribute("aria-describedby") == []
  end

  test "keeps the listbox on the popover when no actions slot is given" do
    {:ok, doc} = Floki.parse_fragment(render_multi([]))

    assert doc |> Floki.find("#filters-role--dropdown") |> Floki.attribute("role") == ["listbox"]
    assert Floki.find(doc, ".combobox-actions") == []

    assert doc |> Floki.find(~s([role="combobox"])) |> Floki.attribute("aria-controls") ==
             ["filters-role--dropdown"]
  end

  test "renders the actions slot and moves the listbox role off the popover" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <MultiSelect.multi_select
        field="filters[role]"
        label="Role"
        search_name="role_search"
        options={[{"Alpha AG", "1"}]}
      >
        <:actions>
          <button type="button" data-clear-selection="true">Clear all</button>
        </:actions>
      </MultiSelect.multi_select>
      """)

    {:ok, doc} = Floki.parse_fragment(html)

    assert doc |> Floki.find(".combobox-actions button") |> Floki.text() == "Clear all"
    assert doc |> Floki.find("#filters-role--dropdown") |> Floki.attribute("role") == []

    assert doc |> Floki.find("#filters-role--dropdown-listbox") |> Floki.attribute("role") ==
             ["listbox"]

    assert doc |> Floki.find(~s([role="combobox"])) |> Floki.attribute("aria-controls") ==
             ["filters-role--dropdown-listbox"]

    assert Floki.find(doc, ".combobox-actions [role]") == []
  end

  test "applies the multi-select listbox ARIA pattern" do
    html = render_multi(value: ["2"])

    assert html =~ ~s(role="listbox")
    assert html =~ ~s(aria-multiselectable="true")
    assert html =~ ~s(aria-selected="true")
    assert html =~ ~s(aria-selected="false")
    refute html =~ "aria-activedescendant"
  end

  test "filters options by the search term" do
    html = render_multi(search_term: "beta")

    assert html =~ "Beta AG"
    refute html =~ "Alpha AG"
  end

  test "renders grouped options with their headers" do
    options = [
      %{label: "AADB", options: [%{label: "admin", value: "1"}]},
      %{label: "Realm", options: [%{label: "owner", value: "3"}]}
    ]

    html = render_multi(options: options, value: ["3"])

    assert html =~ ~s(role="group")
    assert html =~ "AADB"
    assert html =~ ~s(id="filters-role--dropdown-opt-3")
    assert html =~ ~s(value="3" checked)
  end

  describe "disabled options" do
    @mixed [
      {"Alpha AG", "1"},
      %{label: "Beta AG", value: "2", disabled: true}
    ]

    test "renders the checkbox greyed and inert" do
      html = render_multi(options: @mixed)

      assert html =~ ~s(data-disabled="true")
      assert html =~ ~s(value="2" disabled)
    end

    test "carries a selected disabled value, since its checkbox submits nothing" do
      html = render_multi(options: @mixed, value: ["2"])

      # checked on screen, so the user can see what they hold…
      assert html =~ ~s(value="2" checked disabled)
      # …and carried, so it survives the round trip
      assert html =~ ~s(type="hidden" name="filters[role][]" value="2")
    end

    test "carries nothing extra for an ordinary selection" do
      html = render_multi(options: @mixed, value: ["1"])

      assert html =~ ~s(value="1" checked)
      refute html =~ ~s(type="hidden" name="filters[role][]" value="1")
    end

    test "carries both a disabled selection and one the search term hides" do
      options = @mixed ++ [{"Gamma AG", "3"}]
      html = render_multi(options: options, value: ["2", "3"], search_term: "Beta")
      {:ok, doc} = Floki.parse_fragment(html)

      assert doc
             |> Floki.find(~s(div.contents input[type="hidden"]))
             |> Floki.attribute("value") == ["", "2", "3"]
    end

    test "keeps a disabled selection in the summary, which disabling must never hide" do
      assert render_multi(options: @mixed, value: ["2"]) =~ ~s(placeholder="Beta AG")
      assert render_multi(options: @mixed, value: ["1", "2"]) =~ ~s(placeholder="2 selected")
    end

    test "disables every option of a disabled group" do
      options = [
        %{label: "Live", options: [{"Alpha AG", "1"}]},
        %{label: "Legacy", options: [{"Beta AG", "2"}], disabled: true}
      ]

      {:ok, doc} = Floki.parse_fragment(render_multi(options: options, value: ["2"]))

      assert doc
             |> Floki.find("#filters-role--dropdown-opt-2")
             |> Floki.attribute("data-disabled") == ["true"]

      assert doc
             |> Floki.find(~s(div.contents input[type="hidden"]))
             |> Floki.attribute("value") == ["", "2"]
    end
  end

  test "accepts a form field, whose name already ends in []" do
    assigns = %{form: to_form(%{"role_ids" => ["1"]}, as: :user)}

    html =
      rendered_to_string(~H"""
      <MultiSelect.multi_select
        field={@form[:role_ids]}
        label="Roles"
        search_name="role_search"
        options={[{"Alpha AG", "1"}, {"Beta AG", "2"}]}
      />
      """)

    assert html =~ ~s(name="user[role_ids][]")
    refute html =~ ~s(name="user[role_ids][][]")
    assert html =~ ~s(value="1" checked)
  end
end
