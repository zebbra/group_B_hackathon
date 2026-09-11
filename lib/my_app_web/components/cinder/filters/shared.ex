defmodule MyAppWeb.Components.Cinder.Filters.Shared do
  @moduledoc """
  Plumbing shared by the app's `Cinder.Filter` implementations.
  """

  use MyAppWeb, :translations

  import Cinder.Filter, only: [get_option: 3, field_name: 1, filter_id: 2]

  alias Cinder.Filter.Helpers
  alias MyAppWeb.Components.Core.Inputs.Listbox.Options

  @doc "Common assigns for a filter's `render/4`."
  @spec base_assigns(map(), any(), map()) :: map()
  def base_assigns(column, current_value, assigns) do
    filter_options = Map.get(column, :filter_options, [])

    %{
      id: filter_id(Map.get(assigns, :table_id), column.field),
      field: field_name(column.field),
      value: current_value || "",
      options: get_option(filter_options, :options, []),
      prompt: get_option(filter_options, :prompt, ~t"All"m),
      filter_options: filter_options
    }
  end

  @doc "The option list configured on a column, as `render/4` and `process/2` both see it."
  @spec column_options(map()) :: list()
  def column_options(column) do
    column |> Map.get(:filter_options, []) |> get_option(:options, [])
  end

  @doc """
  Whether a raw value may be filtered on at all — unknown and disabled values
  are rejected, and a column with no configured options passes everything.
  """
  @spec selectable?(list(), any()) :: boolean()
  def selectable?([], _value), do: true

  def selectable?(options, value) do
    case Options.find_option(options, value) do
      nil -> false
      item -> not Options.item_disabled(item)
    end
  end

  @doc "Reads the filter's search term from the raw filter params."
  @spec search_term(map(), String.t()) :: String.t()
  def search_term(raw_filter_params, search_key) do
    Map.get(raw_filter_params, search_key, "")
  end

  @doc "As `search_term/2`, but suppresses a term equal to the selection's own display."
  @spec search_term(map(), String.t(), list(), any()) :: String.t()
  def search_term(raw_filter_params, search_key, options, value) do
    term = search_term(raw_filter_params, search_key)

    if term != "" and term in displays_for(options, value), do: "", else: term
  end

  @spec displays_for(list(), any()) :: [String.t()]
  defp displays_for(_options, value) when value in [nil, ""], do: []

  defp displays_for(options, value) do
    options
    |> Options.leaf_options()
    |> Enum.find(fn item -> Options.same?(Options.item_value(item), value) end)
    |> case do
      nil -> []
      item -> Enum.uniq([Options.item_label(item), Options.item_display(item)])
    end
  end

  @doc """
  Processes a single-value filter param into Cinder's filter map, or `nil` when
  the value is blank or not selectable (see `selectable?/2`).
  """
  @spec process_single(any(), atom(), [String.t()], list()) :: map() | nil
  def process_single(raw_value, type, blanks, options \\ [])

  def process_single(raw_value, type, blanks, options) when is_binary(raw_value) do
    trimmed = String.trim(raw_value)

    cond do
      trimmed in blanks -> nil
      not selectable?(options, trimmed) -> nil
      true -> %{type: type, value: trimmed, operator: :equals}
    end
  end

  def process_single(_raw_value, _type, _blanks, _options), do: nil

  @doc "Validates a single-value filter map of the given type."
  @spec validate_single(any(), atom()) :: boolean()
  def validate_single(%{type: type, value: value, operator: :equals}, type) when is_binary(value) do
    value != ""
  end

  def validate_single(_value, _type), do: false

  @doc "Checks whether a single-value filter is empty."
  @spec empty_single?(any(), [String.t()]) :: boolean()
  def empty_single?(nil, _blanks), do: true
  def empty_single?(%{value: value}, blanks), do: empty_single?(value, blanks)
  def empty_single?(value, blanks) when is_binary(value), do: value in blanks
  def empty_single?(_value, _blanks), do: false

  @doc "Builds an `:equals` Ash filter."
  @spec equals_query(term(), term(), any()) :: term()
  def equals_query(query, field, value) do
    Helpers.build_ash_filter(query, field, value, :equals)
  end

  @match_modes %{"~mode:any" => :any, "~mode:all" => :all}

  @doc """
  The sentinel that carries a match mode inside a multi-value filter's list,
  the only part of the filter Cinder round-trips through the URL.
  """
  @spec match_mode_sentinel(:any | :all) :: String.t()
  def match_mode_sentinel(:all), do: "~mode:all"
  def match_mode_sentinel(:any), do: "~mode:any"

  @doc "Whether a value in a multi-value list is a `~mode:` sentinel rather than a selection."
  @spec match_mode?(any()) :: boolean()
  def match_mode?(value), do: is_map_key(@match_modes, value)

  @doc "Splits the `~mode:` sentinel out of a values list, returning the mode and the rest."
  @spec split_match_mode(any()) :: {:any | :all, [String.t()]}
  @spec split_match_mode(any(), atom()) :: {:any | :all, [String.t()]}
  def split_match_mode(value, default \\ :any)

  def split_match_mode(%{value: values}, default), do: split_match_mode(values, default)

  def split_match_mode(values, default) do
    {sentinels, rest} =
      values
      |> List.wrap()
      |> Enum.split_with(&is_map_key(@match_modes, &1))

    mode =
      cond do
        match_mode_sentinel(:all) in sentinels -> :all
        match_mode_sentinel(:any) in sentinels -> :any
        true -> default
      end

    {mode, rest}
  end

  @doc "Builds an `:in` Ash filter honouring the match mode."
  @spec in_query(term(), term(), list(), atom()) :: term()
  def in_query(query, field, values, match_mode) do
    Helpers.build_ash_filter(query, field, values, :in, match_mode: match_mode)
  end
end
