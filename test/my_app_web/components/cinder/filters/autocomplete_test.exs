defmodule MyAppWeb.Components.Cinder.Filters.AutocompleteTest do
  @moduledoc false
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias MyAppWeb.Components.Cinder.Filters.Autocomplete

  defp render(current_value, assigns, filter_options \\ [options: [{"Acme AG", "1"}]]) do
    column = %{field: "company", label: "Company", filter_options: filter_options}

    column
    |> Autocomplete.render(current_value, %{}, assigns)
    |> rendered_to_string()
  end

  test "always offers a blank option labelled by the prompt" do
    html =
      render("1", %{table_id: "users", raw_filter_params: %{}},
        options: [{"Acme AG", "1"}],
        prompt: "All companies"
      )

    assert html =~ "-opt-blank"
    assert html =~ "All companies"
  end

  test "renders the combobox with Cinder's value and search param names" do
    html = render("1", %{table_id: "users", raw_filter_params: %{}})

    assert html =~ ~s(name="filters[company]")
    assert html =~ ~s(name="filters[company_autocomplete_search]")
    assert html =~ ~s(popover="manual")
    assert html =~ ~s(aria-label="All")
    assert html =~ "Acme AG"
  end

  test "ignores a stored search term that echoes the selected label (shows all)" do
    html =
      render(
        "1",
        %{table_id: "users", raw_filter_params: %{"company_autocomplete_search" => "Acme AG"}},
        options: [{"Acme AG", "1"}, {"Beta AG", "2"}]
      )

    assert html =~ "Acme AG"
    assert html =~ "Beta AG"
    refute html =~ "No results found"
  end

  test "ignores a stored search term that equals a grouped leaf's :display" do
    filter_options = [
      options: [
        %{
          label: "AADB",
          options: [%{label: "atm", value: "1", search: "AADB atm", display: "AADB - atm"}]
        },
        %{
          label: "Realm",
          options: [
            %{label: "owner", value: "3", search: "Realm owner", display: "Realm - owner"}
          ]
        }
      ],
      prompt: "All roles"
    ]

    html =
      render(
        "1",
        %{table_id: "users", raw_filter_params: %{"company_autocomplete_search" => "AADB - atm"}},
        filter_options
      )

    assert html =~ ~s(value="AADB - atm")
    assert html =~ ~s(data-label="AADB - atm")
    assert html =~ ~s(data-label="Realm - owner")
    refute html =~ "No results found"
  end

  test "keeps a matching term as a real search when it is not the current selection" do
    html =
      render(
        "",
        %{table_id: "users", raw_filter_params: %{"company_autocomplete_search" => "Acme AG"}},
        options: [{"Acme AG", "1"}, {"Beta AG", "2"}]
      )

    assert html =~ ~s(value="Acme AG")
    assert html =~ "Acme AG"
    refute html =~ "Beta AG"
  end

  test "reflects the stored search term from raw_filter_params" do
    html =
      render("", %{
        table_id: "users",
        raw_filter_params: %{"company_autocomplete_search" => "zzz"}
      })

    assert html =~ ~s(value="zzz")
    refute html =~ "Acme AG"
  end

  test "process/2 wraps a value the way the query layer expects" do
    assert Autocomplete.process("1", %{}) == %{
             type: :autocomplete,
             value: "1",
             operator: :equals
           }

    assert Autocomplete.process("  ", %{}) == nil
  end

  test "process/2 drops a value the column's options do not offer" do
    column = %{
      filter_options: [
        options: [{"Acme AG", "1"}, %{label: "Beta AG", value: "2", disabled: true}]
      ]
    }

    assert Autocomplete.process("1", column) ==
             %{type: :autocomplete, value: "1", operator: :equals}

    assert Autocomplete.process("2", column) == nil
    assert Autocomplete.process("9", column) == nil
  end

  test "empty? and validate agree on blank values" do
    assert Autocomplete.empty?(%{value: ""})
    refute Autocomplete.validate(%{type: :autocomplete, value: "", operator: :equals})
    assert Autocomplete.validate(%{type: :autocomplete, value: "1", operator: :equals})
  end
end
