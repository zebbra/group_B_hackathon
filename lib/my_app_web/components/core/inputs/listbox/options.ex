defmodule MyAppWeb.Components.Core.Inputs.Listbox.Options do
  @moduledoc """
  Pure option-list helpers shared by the listbox inputs (`MyAppWeb.Components.Core.Inputs.select/1`,
  `MyAppWeb.Components.Core.Inputs.combobox/1`, and `MyAppWeb.Components.Core.Inputs.multi_select/1`).

  An **option** is a `{label, value}` tuple, or a map with at least `:label` and
  `:value` plus an optional `:search` string (matched instead of the label), an
  optional `:display` string (shown in the trigger when selected), an optional
  `:badge` (a secondary identifier shown right-aligned in the dropdown row), an
  optional `:disabled` flag with its optional `:disabled_reason`, and any extra
  keys an `:option` slot needs. A `:badge` is data rather than markup so it also
  reaches inputs rendered from a `Cinder.Filter`, whose keyword config cannot
  carry a slot; the same goes for `:disabled`. A **group** is a
  `{label, options}` tuple or a `%{label:, options:}` map; groups are filtered
  independently and empty ones are dropped. A group map carrying
  `disabled: true` disables every option inside it, which promotes its tuple
  options to maps.

  A **disabled** option renders greyed and inert: it cannot be picked, keyboard
  navigation skips it, and its row control carries the HTML `disabled`
  attribute, so it never submits — an input keeps a *selected* disabled value by
  carrying it in a hidden field instead. It is an affordance, not enforcement:
  it shapes what the dropdown offers, never what the params may contain.

  Nothing here knows which input renders it. `dropdown_groups/4` takes a
  `selected?` predicate over option *values*, so single-select passes
  `&same?(&1, value)` and multi-select passes a set-membership check.

  `max_results` caps the *unselected* matches only: every matching selected
  option is always rendered, even when the selection alone exceeds the cap. An
  option that is checked but not on screen cannot be unchecked, and the trigger
  only reports a count, so nothing would say which one was missing. The overflow
  is bounded by the user's own clicks. Selected options still respect the search
  term — one the term hides stays hidden, carried by the input's hidden field.

  Disabled options do not spend the cap either: the visible window is the run of
  matches ending at the `max_results`-th *enabled* one, so a stretch of disabled
  options can never squeeze the selectable ones out of view. The window is only
  bounded by that Nth enabled option — a list holding fewer enabled options than
  the cap renders every match, however many disabled ones that is.

  A selection that would otherwise fall past the cap is pinned into view: to the
  front of a flat list, or to the front of its own group, which keeps its slot
  and its position in group order. When every selection already fits, the
  natural order is left untouched.
  """

  @type option :: {String.t(), any()} | map()
  @type group :: %{label: String.t() | nil, options: [option()]}

  @doc """
  Returns an option's label — the text rendered in its dropdown row.
  """
  @spec item_label(option()) :: String.t()
  def item_label({label, _value}), do: label
  def item_label(%{label: label}), do: label

  @doc """
  Returns an option's value — what the form submits and what the `selected?`
  predicates are given.
  """
  @spec item_value(option()) :: any()
  def item_value({_label, value}), do: value
  def item_value(%{value: value}), do: value

  @doc """
  Returns the text the trigger shows once an option is selected.

  Falls back to the label, so `:display` is only needed when the trigger should
  read differently from the dropdown row.
  """
  @spec item_display(option()) :: String.t()
  def item_display(%{display: display}) when is_binary(display), do: display
  def item_display(item), do: item_label(item)

  @doc """
  Returns the text `matches/2` searches against.

  Falls back to the label, so `:search` is only needed when an option should be
  findable by something it does not display — a synonym, a code, an alias.
  """
  @spec item_search(option()) :: String.t()
  def item_search(%{search: search}) when is_binary(search), do: search
  def item_search(item), do: item_label(item)

  @doc """
  Returns an option's badge as a string, or `nil` when it carries none.
  """
  @spec item_badge(option()) :: String.t() | nil
  def item_badge(%{badge: badge}) when badge not in [nil, ""], do: to_string(badge)
  def item_badge(_item), do: nil

  @doc """
  Returns whether an option is disabled — rendered, but not selectable.

  Only map options can carry the flag; a `{label, value}` tuple has nowhere to
  put it, so tuples are never disabled on their own. They still inherit it from
  a disabled group, which promotes them to maps.
  """
  @spec item_disabled(option()) :: boolean()
  def item_disabled(%{disabled: disabled}), do: !!disabled
  def item_disabled(_item), do: false

  @doc """
  Returns why an option is disabled, or `nil` when it says nothing — or when it
  is not disabled at all, since a reason without the flag would explain
  something the user can still pick.
  """
  @spec item_disabled_reason(option()) :: String.t() | nil
  def item_disabled_reason(%{disabled_reason: reason} = item) when reason not in [nil, ""] do
    if item_disabled(item), do: to_string(reason)
  end

  def item_disabled_reason(_item), do: nil

  @doc """
  Builds the map handed to an `:option` slot.

  A map option keeps its own extra keys; both shapes gain `:label`, `:value`,
  `:selected` and `:disabled`, the last normalised to a boolean so a slot can
  read it without knowing which shape it came from.
  """
  @spec slot_arg(option(), boolean()) :: map()
  def slot_arg({_label, _value} = item, selected?) do
    %{
      label: item_label(item),
      value: item_value(item),
      selected: selected?,
      disabled: item_disabled(item)
    }
  end

  def slot_arg(%{} = item, selected?) do
    Map.merge(item, %{
      label: item_label(item),
      value: item_value(item),
      selected: selected?,
      disabled: item_disabled(item)
    })
  end

  @doc """
  Returns whether the list holds groups rather than flat options.

  Decided by the first element alone — a list is expected to be uniformly
  grouped or uniformly flat.
  """
  @spec grouped?(list()) :: boolean()
  def grouped?([first | _]), do: group?(first)
  def grouped?(_options), do: false

  @doc """
  Returns a group's heading, or `nil` for the unlabelled bucket that
  `dropdown_groups/4` wraps a flat list in.
  """
  @spec group_label(group() | {String.t(), list()}) :: String.t() | nil
  def group_label({label, _options}), do: label
  def group_label(%{label: label}), do: label

  @doc """
  Returns the options a group holds, as written.

  Group-level `disabled: true` is *not* applied here — use `group_leaves/1` for
  the options as they should be rendered.
  """
  @spec group_options(group() | {String.t(), list()}) :: list()
  def group_options({_label, options}), do: options
  def group_options(%{options: options}), do: options

  @doc """
  Returns whether a whole group is disabled, disabling every option in it.

  Only a group map can say so; a `{label, options}` tuple has nowhere to put the
  flag.
  """
  @spec group_disabled?(group() | {String.t(), list()}) :: boolean()
  def group_disabled?(%{disabled: disabled}), do: !!disabled
  def group_disabled?(_group), do: false

  @doc """
  Returns a group's options with the group's own `disabled` flag pushed onto
  each of them, promoting tuples to maps when it applies.
  """
  @spec group_leaves(group() | {String.t(), list()}) :: list()
  def group_leaves(group) do
    options = group_options(group)

    if group_disabled?(group), do: Enum.map(options, &mark_disabled/1), else: options
  end

  @doc """
  Flattens groups into a single option list, leaving an already-flat list
  untouched. Options inside a disabled group come back disabled.
  """
  @spec leaf_options(list()) :: list()
  def leaf_options(options) do
    if grouped?(options), do: Enum.flat_map(options, &group_leaves/1), else: options
  end

  @doc """
  Filters a flat option list by a case-insensitive substring match on
  `item_search/1`. A blank term keeps everything.
  """
  @spec matches(list(), String.t() | nil) :: list()
  def matches(options, term) when term in [nil, ""], do: options

  def matches(options, term) do
    term = String.downcase(term)

    Enum.filter(options, fn item ->
      String.contains?(String.downcase(to_string(item_search(item))), term)
    end)
  end

  @doc """
  Compares two option values by their string form, so a `1` from params matches
  an integer `1` in the option list.

  An empty value never matches anything — a cleared input selects no option
  rather than the one that happens to be blank.
  """
  @spec same?(any(), any()) :: boolean()
  def same?(a, b) when a in [nil, ""] or b in [nil, ""], do: false
  def same?(a, b), do: to_string(a) == to_string(b)

  @doc """
  Returns the id the listbox namespaces its DOM nodes under.

  Uses the given id when there is one, otherwise derives it from the field
  name, since a name like `user[role]` cannot be used as an id.
  """
  @spec base_id(any(), String.t()) :: String.t()
  def base_id(id, _name) when id not in [nil, ""], do: id
  def base_id(_id, name), do: sanitize(name)

  @doc """
  Replaces every character that is not valid in an HTML id with `-`, so
  caller-supplied names and option values can be built into ids and IDREFs
  (`aria-activedescendant`).
  """
  @spec sanitize(String.t()) :: String.t()
  def sanitize(string), do: String.replace(string, ~r/[^A-Za-z0-9_-]/, "-")

  @doc """
  Returns the option matching `value`, or `nil` when none does. Searches inside
  groups, so an option in a disabled group comes back disabled.
  """
  @spec find_option(list(), any()) :: option() | nil
  def find_option(_options, value) when value in [nil, ""], do: nil

  def find_option(options, value) do
    Enum.find(leaf_options(options), fn item -> same?(item_value(item), value) end)
  end

  @doc """
  Returns the trigger text for the option matching `value`, or `nil` when no
  option matches. Searches inside groups.
  """
  @spec display_of(list(), any()) :: String.t() | nil
  def display_of(options, value) do
    case find_option(options, value) do
      nil -> nil
      item -> item_display(item)
    end
  end

  @doc """
  Builds everything the dropdown needs to render, for both grouped and flat
  option lists.

  Returns `{groups, visible, truncated?}`: the groups to render in order (a
  flat list comes back as a single `nil`-labelled group, so the template has
  one shape to walk), the flat list of options actually on screen, and whether
  `max_results` hid any *selectable* match. Pass `nil` as `max_results` to cap
  nothing.

  Disabled matches are counted on neither side: they cost no budget, so a run
  of them past the cap must not raise the "type to search more" hint when every
  option the user could pick is already on screen.

  `selected?` is a predicate over option *values* — single-select passes
  `&same?(&1, value)`, multi-select a set-membership check. It only affects
  which options survive the cap; see the module doc on how selections are
  pinned into view.
  """
  @spec dropdown_groups(list(), String.t() | nil, pos_integer() | nil, (any() -> boolean())) ::
          {[group()], list(), boolean()}
  def dropdown_groups(options, term, max_results, selected?) do
    if grouped?(options) do
      matched =
        options
        |> Enum.map(fn group -> {group_label(group), matches(group_leaves(group), term)} end)
        |> Enum.reject(fn {_label, options} -> options == [] end)

      total =
        Enum.reduce(matched, 0, fn {_label, options}, sum -> sum + count_enabled(options) end)

      groups = cap_groups(matched, selected?, max_results)
      visible = Enum.flat_map(groups, & &1.options)

      {groups, visible, count_enabled(visible) < total}
    else
      matched = matches(options, term)
      visible = visible_options(matched, selected?, max_results)

      {[%{label: nil, options: visible}], visible, count_enabled(visible) < count_enabled(matched)}
    end
  end

  @spec cap_groups(list(), (any() -> boolean()), pos_integer() | nil) :: [group()]
  defp cap_groups(groups, _selected?, nil) do
    Enum.map(groups, fn {label, options} -> %{label: label, options: options} end)
  end

  defp cap_groups(groups, selected?, max_results) do
    counts = Enum.map(groups, fn {_label, options} -> count_selected(options, selected?) end)

    {capped, _remaining} =
      groups
      |> Enum.with_index()
      |> Enum.reduce({[], max_results}, fn {{label, options}, index}, {acc, remaining} ->
        reserved = counts |> Enum.drop(index + 1) |> Enum.sum()

        case take_pinned(options, selected?, max(remaining - reserved, 0)) do
          [] -> {acc, remaining}
          taken -> {[%{label: label, options: taken} | acc], remaining - count_enabled(taken)}
        end
      end)

    Enum.reverse(capped)
  end

  @spec visible_options(list(), (any() -> boolean()), pos_integer() | nil) :: list()
  defp visible_options(matched, _selected?, nil), do: matched

  defp visible_options(matched, selected?, max_results) do
    take_pinned(matched, selected?, max_results)
  end

  @spec take_pinned(list(), (any() -> boolean()), non_neg_integer()) :: list()
  defp take_pinned(options, selected?, limit) do
    taken = take_budgeted(options, limit)

    if Enum.all?(options, &(not selected?.(item_value(&1)) or &1 in taken)) do
      taken
    else
      {selected, rest} = Enum.split_with(options, &selected?.(item_value(&1)))

      selected ++ take_budgeted(rest, max(limit - count_enabled(selected), 0))
    end
  end

  @spec take_budgeted(list(), non_neg_integer()) :: list()
  defp take_budgeted(options, limit) do
    {taken, _left} =
      Enum.reduce_while(options, {[], limit}, fn item, {acc, left} ->
        cond do
          left <= 0 -> {:halt, {acc, left}}
          item_disabled(item) -> {:cont, {[item | acc], left}}
          true -> {:cont, {[item | acc], left - 1}}
        end
      end)

    Enum.reverse(taken)
  end

  @spec count_selected(list(), (any() -> boolean())) :: non_neg_integer()
  defp count_selected(options, selected?) do
    options
    |> Enum.filter(&selected?.(item_value(&1)))
    |> count_enabled()
  end

  @spec count_enabled(list()) :: non_neg_integer()
  defp count_enabled(options), do: Enum.count(options, &(not item_disabled(&1)))

  @spec mark_disabled(option()) :: map()
  defp mark_disabled({label, value}), do: %{label: label, value: value, disabled: true}
  defp mark_disabled(%{} = item), do: Map.put(item, :disabled, true)

  @spec group?(any()) :: boolean()
  defp group?({_label, options}) when is_list(options), do: true
  defp group?(%{options: options}) when is_list(options), do: true
  defp group?(_option), do: false
end
