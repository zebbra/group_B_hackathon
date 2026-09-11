defmodule MyAppWeb.Components.Core.Inputs.ListboxTest do
  @moduledoc false
  use MyAppWeb.ConnCase, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias MyAppWeb.Components.Core.Inputs.Listbox

  defp render_listbox(overrides) do
    groups = [%{label: nil, options: [{"Alpha", "1"}, {"Beta", "2"}]}]

    assigns =
      Keyword.merge(
        [
          id: "to_id-dropdown",
          anchor: "--to_id-anchor",
          name: "to_id",
          groups: groups,
          selected?: fn value -> value == "2" end
        ],
        overrides
      )

    render_component(&Listbox.listbox/1, assigns)
  end

  defp render_rows(options, overrides \\ []) do
    html = render_listbox([groups: [%{label: nil, options: options}]] ++ overrides)
    {:ok, doc} = Floki.parse_fragment(html)

    Floki.find(doc, ".combobox-option")
  end

  test "renders a badge after the label, only for options that carry one" do
    groups = [
      %{
        label: nil,
        options: [
          %{label: "AGF-L1", value: "1", badge: 2790},
          %{label: "Beta", value: "2"}
        ]
      }
    ]

    {:ok, doc} = Floki.parse_fragment(render_listbox(groups: groups))
    rows = Floki.find(doc, ".combobox-option")

    assert rows |> Enum.at(0) |> Floki.find(".badge") |> Floki.text() |> String.trim() == "2790"
    assert rows |> Enum.at(1) |> Floki.find(".badge") == []

    # the label keeps flex-1, so the badge is pushed to the right edge of the row
    assert rows |> Enum.at(0) |> Floki.find("span.flex-1") |> Floki.text() == "AGF-L1"
  end

  test "renders an anchor-positioned popover listbox" do
    html = render_listbox([])

    assert html =~ ~s(id="to_id-dropdown")
    assert html =~ ~s(popover="manual")
    assert html =~ ~s(role="listbox")
    assert html =~ "position-anchor: --to_id-anchor"
  end

  test "renders a radio per option, checking the selected one" do
    html = render_listbox([])

    assert html =~ ~s(id="to_id-dropdown-opt-1")
    assert html =~ ~s(type="radio" name="to_id" value="2" checked)
    assert html =~ ~s(data-label="Alpha")
    assert html =~ "✓"
  end

  test "leaves aria-selected and aria-activedescendant to the hook" do
    html = render_listbox([])

    refute html =~ "aria-selected"
    refute html =~ "aria-activedescendant"
  end

  test "renders group sections with labelled headers" do
    groups = [
      %{label: "AADB", options: [%{label: "admin", value: "1"}]},
      %{label: "Realm", options: [%{label: "owner", value: "3"}]}
    ]

    html = render_listbox(groups: groups)

    assert html =~ ~s(role="group")
    assert html =~ ~s(id="to_id-dropdown-group-0")
    assert html =~ ~s(aria-labelledby="to_id-dropdown-group-0")
    assert html =~ ~s(id="to_id-dropdown-group-1")
    assert html =~ "AADB"
  end

  test "renders the blank row only when allow_blank is set, checked when blank_selected" do
    refute render_listbox([]) =~ "-opt-blank"

    checked = render_listbox(allow_blank: true, blank_label: "Any", blank_selected: true)
    assert checked =~ ~s(id="to_id-dropdown-opt-blank")
    assert checked =~ "Any"
    assert checked =~ ~s(type="radio" name="to_id" value="" checked)

    unchecked = render_listbox(allow_blank: true, blank_selected: false)
    refute unchecked =~ ~s(value="" checked)
  end

  test "shows the empty message only when there is nothing to show and no blank row" do
    empty = [%{label: nil, options: []}]

    assert render_listbox(groups: empty) =~ "No results found"
    assert render_listbox(groups: [], empty_message: "Nothing here") =~ "Nothing here"
    refute render_listbox(groups: empty, allow_blank: true) =~ "No results found"
    refute render_listbox([]) =~ "No results found"
  end

  test "shows the more hint only when one is given" do
    assert render_listbox(more_hint: "Type to search more options…") =~
             "Type to search more options…"

    refute render_listbox([]) =~ "Type to search more"
  end

  test "renders rows through a forwarded option slot" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <Listbox.listbox
        id="to_id-dropdown"
        anchor="--to_id-anchor"
        name="to_id"
        groups={[%{label: nil, options: [%{label: "Alpha", value: "1"}]}]}
        selected?={fn value -> value == "1" end}
        option_slot={[
          %{
            __slot__: :option,
            inner_block: fn _changed, opt ->
              Phoenix.HTML.raw(~s(<span data-row="#{opt.value}">#{opt.label}</span>))
            end
          }
        ]}
      />
      """)

    assert html =~ ~s(data-row="1")
    refute html =~ "✓"
  end

  test "renders radios with the check glyph by default" do
    html = render_listbox([])

    assert html =~ ~s(type="radio")
    refute html =~ ~s(type="checkbox")
    assert html =~ "✓"
    refute html =~ "aria-multiselectable"
    refute html =~ "aria-selected"
  end

  test "input_type checkbox renders visible checkboxes instead of the glyph" do
    html = render_listbox(input_type: :checkbox)

    assert html =~ ~s(type="checkbox")
    refute html =~ ~s(type="radio")
    assert html =~ "checkbox checkbox-sm shrink-0"
    assert html =~ ~s(name="to_id" value="2" checked)
    refute html =~ "✓"
  end

  test "multiselectable marks the listbox" do
    assert render_listbox(multiselectable: true) =~ ~s(aria-multiselectable="true")
    refute render_listbox([]) =~ "aria-multiselectable"
  end

  test "aria_selected renders the checked state on every option" do
    html = render_listbox(aria_selected: true)

    assert html =~ ~s(aria-selected="true")
    assert html =~ ~s(aria-selected="false")
  end

  test "aria_selected stays off for the single-select components" do
    refute render_listbox(input_type: :checkbox, multiselectable: true) =~ "aria-selected"
  end

  describe "disabled options" do
    test "marks the row for the hooks, the stylesheet and assistive tech" do
      rows =
        render_rows([
          %{label: "Archived", value: "1", disabled: true},
          %{label: "Beta", value: "2"}
        ])

      assert rows |> Enum.at(0) |> Floki.attribute("data-disabled") == ["true"]
      assert rows |> Enum.at(0) |> Floki.attribute("aria-disabled") == ["true"]

      assert rows |> Enum.at(1) |> Floki.attribute("data-disabled") == []
      assert rows |> Enum.at(1) |> Floki.attribute("aria-disabled") == []
    end

    test "disables the row control, so nothing it does can submit the value" do
      rows =
        render_rows([
          %{label: "Archived", value: "1", disabled: true},
          %{label: "Beta", value: "2"}
        ])

      assert rows |> Enum.at(0) |> Floki.find("input") |> Floki.attribute("disabled") ==
               ["disabled"]

      assert rows |> Enum.at(1) |> Floki.find("input") |> Floki.attribute("disabled") == []
    end

    test "keeps a disabled option checked when it is the selection" do
      rows =
        render_rows(
          [%{label: "Archived", value: "2", disabled: true}],
          input_type: :checkbox
        )

      input = Floki.find(rows, "input")

      assert Floki.attribute(input, "checked") == ["checked"]
      assert Floki.attribute(input, "disabled") == ["disabled"]
    end

    test "renders a reason as a title and folds it into the accessible name" do
      rows =
        render_rows([
          %{label: "Archived", value: "1", disabled: true, disabled_reason: "Retired in 2025"}
        ])

      assert Floki.attribute(rows, "title") == ["Retired in 2025"]
      assert rows |> Floki.find("span.sr-only") |> Floki.text() =~ "Retired in 2025"
    end

    test "renders no reason when there is none, or when the option is not disabled" do
      plain = render_rows([%{label: "Archived", value: "1", disabled: true}])

      assert Floki.attribute(plain, "title") == []
      assert Floki.find(plain, "span.sr-only") == []

      unflagged =
        render_rows([%{label: "Archived", value: "1", disabled_reason: "Retired in 2025"}])

      assert Floki.attribute(unflagged, "title") == []
      assert Floki.find(unflagged, "span.sr-only") == []
    end

    test "leaves the blank row alone, since it clears rather than selects" do
      rows = render_rows([%{label: "Archived", value: "1", disabled: true}], allow_blank: true)

      assert rows |> Enum.at(0) |> Floki.attribute("id") == ["to_id-dropdown-opt-blank"]
      assert rows |> Enum.at(0) |> Floki.attribute("data-disabled") == []
      assert rows |> Enum.at(0) |> Floki.find("input") |> Floki.attribute("disabled") == []
    end

    test "hands the flag to an option slot" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Listbox.listbox
          id="to_id-dropdown"
          anchor="--to_id-anchor"
          name="to_id"
          groups={[
            %{
              label: nil,
              options: [
                %{label: "Archived", value: "1", disabled: true},
                %{label: "Beta", value: "2"}
              ]
            }
          ]}
          selected?={fn value -> value == "1" end}
          option_slot={[
            %{
              __slot__: :option,
              inner_block: fn _changed, opt ->
                Phoenix.HTML.raw(~s(<span data-off="#{opt.disabled}">#{opt.label}</span>))
              end
            }
          ]}
        />
        """)

      assert html =~ ~s(data-off="true")
      assert html =~ ~s(data-off="false")
    end
  end
end
