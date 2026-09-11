defmodule MyAppWeb.Components.Cinder.Filters.Autocomplete do
  @moduledoc """
  Renders Cinder's `:autocomplete` filter as
  `MyAppWeb.Components.Core.Inputs.combobox/1`, overriding the built-in type
  from `config/config.exs`.

  Values and querying match `Cinder.Filters.Autocomplete`, and the search param
  keeps the `<field>_autocomplete_search` suffix so `clear_filter` still wipes
  the term. `process/2` drops a value the column's options do not offer.
  """

  @behaviour Cinder.Filter

  use MyAppWeb, :html

  import Cinder.Filter, only: [get_option: 3]

  alias MyAppWeb.Components.Cinder.Filters.Shared
  alias MyAppWeb.Components.Core.Inputs
  alias Phoenix.LiveView.Rendered

  @blanks [""]
  @default_max_results 15

  @impl Cinder.Filter
  @spec render(map(), any(), map(), map()) :: Rendered.t()
  def render(column, current_value, _theme, assigns) do
    base = Shared.base_assigns(column, current_value, assigns)
    search_key = "#{column.field}_autocomplete_search"
    raw_filter_params = Map.get(assigns, :raw_filter_params, %{})
    label = column.label

    assigns =
      Map.merge(base, %{
        search_name: "filters[#{search_key}]",
        search_term: Shared.search_term(raw_filter_params, search_key, base.options, base.value),
        placeholder: get_option(base.filter_options, :placeholder, ~t"Search #{label}..."m),
        max_results: get_option(base.filter_options, :max_results, @default_max_results)
      })

    ~H"""
    <Inputs.combobox
      id={@id}
      field={@field}
      value={@value}
      options={@options}
      search_name={@search_name}
      search_term={@search_term}
      placeholder={@placeholder}
      max_results={@max_results}
      allow_blank
      blank_label={@prompt}
      class="md:min-w-40"
      aria-label={@prompt}
    />
    """
  end

  @impl Cinder.Filter
  @spec process(any(), map()) :: map() | nil
  def process(raw_value, column) do
    Shared.process_single(raw_value, :autocomplete, @blanks, Shared.column_options(column))
  end

  @impl Cinder.Filter
  @spec validate(any()) :: boolean()
  def validate(value), do: Shared.validate_single(value, :autocomplete)

  @impl Cinder.Filter
  @spec default_options() :: Keyword.t()
  def default_options do
    [options: [], placeholder: nil, prompt: nil, max_results: @default_max_results]
  end

  @impl Cinder.Filter
  @spec empty?(any()) :: boolean()
  def empty?(value), do: Shared.empty_single?(value, @blanks)

  @impl Cinder.Filter
  @spec build_query(term(), term(), map()) :: term()
  def build_query(query, field, %{value: value}), do: Shared.equals_query(query, field, value)
end
