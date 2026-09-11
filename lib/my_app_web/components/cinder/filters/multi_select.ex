defmodule MyAppWeb.Components.Cinder.Filters.MultiSelect do
  @moduledoc """
  Renders Cinder's `:multi_select` filter as
  `MyAppWeb.Components.Core.Inputs.multi_select/1`, overriding the built-in type
  from `config/config.exs`. `:multi_checkboxes` keeps its own inline list.

  Values and querying stay drop-in compatible (`type: :multi_select`, `:in`,
  `match_mode`), and the search param keeps the `<field>_autocomplete_search`
  suffix so `clear_filter` still wipes the term. `process/2` drops values the
  column's options do not offer, keeping the `~mode:` sentinels.

  The dropdown's `:actions` row holds *Clear all*, which pushes `clear_filter`,
  and a *Match all* toggle that switches `match_mode` at runtime. The toggle is
  an ordinary checkbox in the same `<field>[]` array, riding the values list as
  a `~mode:` sentinel (`Shared.match_mode_sentinel/1`) so the mode survives a
  reload or a shared link.
  """

  @behaviour Cinder.Filter

  use MyAppWeb, :html

  import Cinder.Filter, only: [get_option: 3]

  alias MyAppWeb.Components.Cinder.Filters.Shared
  alias MyAppWeb.Components.Core.Inputs
  alias Phoenix.LiveView.Rendered

  @default_max_results 15

  @impl Cinder.Filter
  @spec render(map(), any(), map(), map()) :: Rendered.t()
  def render(column, current_value, _theme, assigns) do
    base = Shared.base_assigns(column, current_value, assigns)
    search_key = "#{column.field}_autocomplete_search"
    raw_filter_params = Map.get(assigns, :raw_filter_params, %{})
    default_mode = get_option(base.filter_options, :match_mode, :any)
    {match_mode, values} = Shared.split_match_mode(current_value, default_mode)
    label = column.label

    assigns =
      Map.merge(base, %{
        values: values,
        match_mode: match_mode,
        default_mode: default_mode,
        array_name: "#{base.field}[]",
        search_name: "filters[#{search_key}]",
        search_term: Shared.search_term(raw_filter_params, search_key),
        placeholder: get_option(base.filter_options, :placeholder, ~t"Search #{label}..."m),
        max_results: get_option(base.filter_options, :max_results, @default_max_results),
        clear_key: column.field,
        target: Map.get(assigns, :target)
      })

    ~H"""
    <Inputs.multi_select
      id={@id}
      field={@field}
      value={@values}
      options={@options}
      search_name={@search_name}
      search_term={@search_term}
      placeholder={@placeholder}
      max_results={@max_results}
      aria-label={@prompt}
      class="md:min-w-40"
    >
      <:actions>
        <div class="flex items-center justify-between gap-2">
          <label class="flex cursor-pointer items-center gap-2 py-1 pl-1 text-xs">
            <input
              :if={@default_mode == :all}
              type="hidden"
              name={@array_name}
              value={Shared.match_mode_sentinel(:any)}
            />
            <input
              type="checkbox"
              name={@array_name}
              value={Shared.match_mode_sentinel(:all)}
              checked={@match_mode == :all}
              class="checkbox checkbox-xs"
            />
            <span>{~t"Match all"m}</span>
          </label>

          <.button
            type="button"
            style={:ghost}
            size={:xs}
            phx-click="clear_filter"
            phx-value-key={@clear_key}
            phx-target={@target}
            data-clears-search="true"
            disabled={@values == []}
          >
            {~t"Clear all"m}
          </.button>
        </div>
      </:actions>
    </Inputs.multi_select>
    """
  end

  @impl Cinder.Filter
  @spec process(any(), map()) :: map() | nil
  def process(raw_value, column) do
    default_mode = get_option(Map.get(column, :filter_options, []), :match_mode, :any)
    options = Shared.column_options(column)

    values =
      raw_value
      |> List.wrap()
      |> Enum.reject(&(&1 == "" or is_nil(&1)))
      |> Enum.filter(&(Shared.match_mode?(&1) or Shared.selectable?(options, &1)))

    {match_mode, selected} = Shared.split_match_mode(values, default_mode)

    if selected == [] do
      nil
    else
      %{type: :multi_select, value: values, operator: :in, match_mode: match_mode}
    end
  end

  @impl Cinder.Filter
  @spec validate(any()) :: boolean()
  def validate(%{type: :multi_select, value: values, operator: :in} = filter_value) when is_list(values) do
    {_mode, selected} = Shared.split_match_mode(values)

    selected != [] and Enum.all?(values, &is_binary/1) and
      Map.get(filter_value, :match_mode, :any) in [:any, :all]
  end

  def validate(_value), do: false

  @impl Cinder.Filter
  @spec default_options() :: Keyword.t()
  def default_options, do: [options: [], match_mode: :any, prompt: nil]

  @impl Cinder.Filter
  @spec empty?(any()) :: boolean()
  def empty?(value) do
    {_mode, selected} = Shared.split_match_mode(value)

    selected == []
  end

  @impl Cinder.Filter
  @spec build_query(term(), term(), map()) :: term()
  def build_query(query, field, filter_value) do
    default_mode = Map.get(filter_value, :match_mode, :any)
    {match_mode, values} = Shared.split_match_mode(filter_value, default_mode)

    Shared.in_query(query, field, values, match_mode)
  end
end
