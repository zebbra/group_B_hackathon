defmodule MyAppWeb.Components.Core.Inputs.SelectTest do
  @moduledoc false
  use MyAppWeb.ConnCase, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias MyAppWeb.Components.Core.Inputs.Select

  @options [{"Physical", "physical"}, {"Technical", "technical"}]

  defp render_select(overrides) do
    assigns = Keyword.merge([field: "type", label: "Type", options: @options], overrides)

    render_component(&Select.select/1, assigns)
  end

  test "renders a button trigger, not a text input, and no debounce" do
    html = render_select(placeholder: "All types", value: "technical")

    assert html =~ ~s(<button)
    assert html =~ ~s(id="type-button" role="combobox")
    assert html =~ ~s(aria-haspopup="listbox")
    assert html =~ ~s(aria-expanded="false")
    assert html =~ ~s(aria-controls="type-dropdown")
    refute html =~ ~s(type="text")
    refute html =~ "phx-debounce"
  end

  test "shows the selection, or the placeholder when blank" do
    selected = render_select(placeholder: "All types", value: "technical")
    assert selected =~ "Technical"
    refute selected =~ ~s(combobox-value flex-1 truncate combobox-placeholder)

    blank = render_select(placeholder: "All types", value: nil)
    assert blank =~ "All types"
    assert blank =~ "combobox-placeholder"
  end

  test "renders the options with their radios and a caret" do
    html = render_select(value: "physical")

    assert html =~ ~s(name="type" value="physical" checked)
    assert html =~ ~s(id="type-dropdown-opt-technical")
    assert html =~ "combobox-caret"
  end

  test "renders every option, with no cap and no more-results hint" do
    options = for i <- 1..30, do: {"opt-#{i}", "#{i}"}
    html = render_select(options: options)

    assert html =~ ~s(id="type-dropdown-opt-30")
    refute html =~ "Type to search more"
  end

  test "renders grouped options as labelled listbox groups" do
    options = [
      {"AADB", [{"admin", "1"}, {"viewer", "2"}]},
      {"Realm", [{"owner", "3"}]}
    ]

    html = render_select(options: options, value: "3")

    assert html =~ ~s(role="group")
    assert html =~ ~s(id="type-dropdown-group-0")
    assert html =~ "AADB"
    assert html =~ ~s(id="type-dropdown-opt-3")
    assert html =~ ~s(value="3" checked)
  end

  test "offers a blank option when allow_blank is set" do
    html = render_select(allow_blank: true, blank_label: "Select a type", value: nil)

    assert html =~ ~s(id="type-dropdown-opt-blank")
    assert html =~ "Select a type"
    assert html =~ ~s(type="radio" name="type" value="" checked)
  end

  test "renders the dropdown as an anchor-positioned popover" do
    html = render_select([])

    assert html =~ ~s(popover="manual")
    assert html =~ "anchor-name: --type-anchor"
    assert html =~ "position-anchor: --type-anchor"
  end

  test "does not render a hidden fallback input" do
    refute render_select(value: "physical") =~ ~s(type="hidden")
  end

  test "checks exactly one radio for the selected value" do
    options = [{"Physical", "physical"}, {"Technical", "technical"}, {"Other", "other"}]
    html = render_select(options: options, value: "technical")

    assert ~r/checked/ |> Regex.scan(html) |> length() == 1
  end

  test "renders every option within a group, not just the first" do
    options = [
      {"AADB", [{"admin", "1"}, {"viewer", "2"}]},
      {"Realm", [{"owner", "3"}]}
    ]

    html = render_select(options: options)

    assert html =~ ~s(id="type-dropdown-opt-1")
    assert html =~ ~s(id="type-dropdown-opt-2")
    assert html =~ ~s(id="type-dropdown-opt-3")
  end

  describe "disabled options" do
    @mixed [
      %{label: "Physical", value: "physical"},
      %{label: "Archived", value: "archived", disabled: true}
    ]

    test "renders the option greyed and inert, and never checks it unasked" do
      html = render_select(options: @mixed, value: "physical")

      assert html =~ ~s(data-disabled="true")
      assert html =~ ~s(value="archived" disabled)
      refute html =~ ~s(value="archived" checked)
    end

    test "carries a disabled selection in a hidden input, since its radio submits nothing" do
      html = render_select(options: @mixed, value: "archived")

      assert html =~ ~s(<input type="hidden" name="type" value="archived")
      # the row still shows as the current choice
      assert html =~ ~s(value="archived" checked disabled)
      assert html =~ "Archived"
    end

    test "carries nothing when the selection is an ordinary option" do
      refute render_select(options: @mixed, value: "physical") =~ ~s(type="hidden")
      refute render_select(options: @mixed, value: nil) =~ ~s(type="hidden")
    end

    test "carries nothing for a value no option matches" do
      refute render_select(options: @mixed, value: "gone") =~ ~s(type="hidden")
    end

    test "wraps the hidden input so its appearance cannot shift the trigger" do
      {:ok, doc} = Floki.parse_fragment(render_select(options: @mixed, value: "archived"))
      wrapper = Floki.find(doc, "div.contents")

      assert wrapper |> Floki.find(~s(input[type="hidden"])) |> Floki.attribute("value") ==
               ["archived"]

      assert Floki.find(wrapper, ~s([role="combobox"])) == []
    end

    test "disables every option of a disabled group" do
      options = [
        {"Live", [{"Physical", "physical"}]},
        %{label: "Legacy", options: [{"Archived", "archived"}], disabled: true}
      ]

      {:ok, doc} = Floki.parse_fragment(render_select(options: options, value: "archived"))

      assert doc
             |> Floki.find("#type-dropdown-opt-archived")
             |> Floki.attribute("data-disabled") == ["true"]

      assert doc
             |> Floki.find("#type-dropdown-opt-physical")
             |> Floki.attribute("data-disabled") == []

      # and the group's own selection is carried, exactly like a flat disabled option
      assert doc
             |> Floki.find(~s(input[type="hidden"]))
             |> Floki.attribute("value") == ["archived"]
    end
  end

  test "renders each row through the :option slot with label/value/selected" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Select.select
        field="type"
        label="Type"
        value="technical"
        options={[{"Physical", "physical"}, {"Technical", "technical"}]}
      >
        <:option :let={opt}>
          <span data-row={opt.value} data-selected={to_string(opt.selected)}>{opt.label}</span>
        </:option>
      </Select.select>
      """)

    assert html =~ ~s(data-row="physical" data-selected="false")
    assert html =~ ~s(data-row="technical" data-selected="true")
    refute html =~ "✓"
  end
end
