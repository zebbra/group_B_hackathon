defmodule MyAppWeb.Components.Cinder.Filters.SelectTest do
  @moduledoc false
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias MyAppWeb.Components.Cinder.Filters.Select

  defp render(current_value, assigns, filter_options) do
    column = %{field: "type", label: "Type", filter_options: filter_options}

    column
    |> Select.render(current_value, %{}, assigns)
    |> rendered_to_string()
  end

  test "renders a select-only listbox (button trigger, no text input, no search)" do
    html =
      render("physical", %{table_id: "users", raw_filter_params: %{}},
        options: [{"Physical", "physical"}, {"Technical", "technical"}],
        prompt: "All types"
      )

    assert html =~ ~s(<button)
    assert html =~ ~s(role="combobox")
    assert html =~ ~s(role="listbox")
    assert html =~ ~s(aria-label="All types")
    refute html =~ ~s(type="text")
    refute html =~ "phx-debounce"
  end

  test "names the trigger what the surrounding label points its for at" do
    html =
      render("physical", %{table_id: "users", raw_filter_params: %{}},
        options: [{"Physical", "physical"}],
        prompt: "All types"
      )

    assert html =~ ~s(id="users-filter-type-button" role="combobox")
  end

  test "uses the prompt as placeholder and blank option, and shows the selection" do
    html =
      render("physical", %{table_id: "users", raw_filter_params: %{}},
        options: [{"Physical", "physical"}, {"Technical", "technical"}],
        prompt: "All types"
      )

    assert html =~ "-opt-blank"
    assert html =~ "All types"
    assert html =~ "Physical"
    assert html =~ ~s(name="filters[type]" value="physical" checked)
  end

  test "renders a disabled option greyed and inert" do
    html =
      render("physical", %{table_id: "users", raw_filter_params: %{}},
        options: [
          {"Physical", "physical"},
          %{label: "Archived", value: "archived", disabled: true}
        ],
        prompt: "All types"
      )

    assert html =~ ~s(data-disabled="true")
    assert html =~ ~s(value="archived" disabled)
  end

  test "renders every option, ignoring the combobox's result cap" do
    options = for i <- 1..30, do: {"opt-#{i}", "#{i}"}

    html =
      render("", %{table_id: "users", raw_filter_params: %{}},
        options: options,
        prompt: "All types"
      )

    assert html =~ ~s(value="30")
    refute html =~ "Type to search more"
  end

  test "process/2 is a drop-in for the built-in :select shape" do
    assert Select.process("physical", %{}) == %{
             type: :select,
             value: "physical",
             operator: :equals
           }

    assert Select.process("  ", %{}) == nil
    assert Select.process("all", %{}) == nil
  end

  describe "process/2 against the column's options" do
    @options [
      options: [
        {"Physical", "physical"},
        %{label: "Archived", value: "archived", disabled: true}
      ]
    ]

    test "keeps a value the user could have picked" do
      assert Select.process("physical", %{filter_options: @options}) ==
               %{type: :select, value: "physical", operator: :equals}
    end

    test "drops a disabled value, which only a hand-edited URL could have sent" do
      assert Select.process("archived", %{filter_options: @options}) == nil
    end

    test "drops a value no option matches" do
      assert Select.process("gone", %{filter_options: @options}) == nil
    end

    test "drops a value inside a disabled group" do
      column = %{
        filter_options: [
          options: [
            {"Live", [{"Physical", "physical"}]},
            %{label: "Legacy", options: [{"Archived", "archived"}], disabled: true}
          ]
        ]
      }

      assert Select.process("physical", column) ==
               %{type: :select, value: "physical", operator: :equals}

      assert Select.process("archived", column) == nil
    end

    test "checks nothing when the column configures no options" do
      assert Select.process("anything", %{filter_options: [options: []]}) ==
               %{type: :select, value: "anything", operator: :equals}

      assert Select.process("anything", %{}) ==
               %{type: :select, value: "anything", operator: :equals}
    end
  end

  test "empty? and validate agree on blank values (including the 'all' sentinel)" do
    assert Select.empty?(%{value: ""})
    assert Select.empty?("all")
    refute Select.validate(%{type: :select, value: "", operator: :equals})
    assert Select.validate(%{type: :select, value: "x", operator: :equals})
  end
end
