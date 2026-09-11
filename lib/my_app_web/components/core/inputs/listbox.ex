defmodule MyAppWeb.Components.Core.Inputs.Listbox do
  @moduledoc """
  The dropdown shared by the listbox inputs (`MyAppWeb.Components.Core.Inputs.select/1`,
  `MyAppWeb.Components.Core.Inputs.combobox/1`, and `MyAppWeb.Components.Core.Inputs.multi_select/1`).

  `listbox/1` renders the popover and nothing else: no wrapper element, no
  trigger, no `phx-hook`. Each input owns its own wrapper and its own colocated
  hook, so behaviour that differs between them — focus, open/close, keyboard,
  search — stays where it belongs.

  The dropdown is a top-layer `popover` anchored to the trigger via CSS anchor
  positioning, so it is never clipped by a surrounding `<dialog>` or `overflow`
  container. ARIA follows the [combobox pattern](https://www.w3.org/WAI/ARIA/apg/patterns/combobox/):
  each row is an `option`, and `role="listbox"` sits on the popover itself —
  or on an inner element when an `:actions` row is supplied, since a listbox may
  not contain interactive children. Single-select inputs leave
  `aria-selected` and `aria-activedescendant` to their hook, which sets them on
  the active option only while the listbox has visual focus. An input that opts
  into `aria_selected` instead renders it server-side on every option, meaning
  *checked* rather than *active* — the multi-select listbox pattern, needed
  because a visible checkbox makes `role="option"` presentational.

  A disabled option renders `aria-disabled`, a `data-disabled` marker the hooks
  and the stylesheet key off, and the HTML `disabled` attribute on its row
  control. A `:disabled_reason` becomes the row's `title` and a visually hidden
  span, folding it into the option's accessible name.
  """

  use MyAppWeb, :html

  alias MyAppWeb.Components.Core.Inputs.Listbox.Options
  alias Phoenix.LiveView.Rendered

  @doc """
  Attributes shared by every input that renders a `listbox/1`.
  """
  @spec option_attributes() :: Macro.t()
  defmacro option_attributes do
    quote do
      attr :options, :list,
        required: true,
        doc:
          "`{label, value}` tuples, or maps with at least `:label` and `:value` " <>
            "(plus an optional `:search` string, an optional `:display` string shown in " <>
            "the trigger when selected, an optional `:badge` shown right-aligned in the " <>
            "row, an optional `:disabled` flag with its optional `:disabled_reason`, and " <>
            "any extra keys your `:option` slot needs). " <>
            "Pass `{group_label, options}` tuples or `%{label:, options:}` maps to render " <>
            "groups; a group map with `disabled: true` disables every option inside it."

      attr :max_results, :integer,
        default: nil,
        doc:
          "Maximum *unselected, enabled* options rendered; `nil` renders all of them. " <>
            "Selected options always render, so a selection larger than this exceeds it " <>
            "rather than hiding a checked option the user could then never uncheck; " <>
            "disabled options do not spend the cap either."

      attr :allow_blank, :boolean,
        default: false,
        doc: "Offer a blank option that clears the field (submits an empty value)."

      attr :blank_label, :string,
        default: nil,
        doc: ~S(Label for the blank option. Defaults to a translated "None".)

      slot :option,
        doc:
          "Custom rendering for each dropdown row. Receives the option (map) merged with " <>
            "`:label`, `:value`, `:selected`, and `:disabled`. The row's radio or checkbox " <>
            "input stays " <>
            "in place (hidden for a radio, visible for a checkbox), so selection and the " <>
            "trigger display keep working."
    end
  end

  attr :id, :string, required: true

  attr :label, :string,
    default: nil,
    doc:
      "Accessible name for the listbox. Callers pass their visible label, falling back to the " <>
        "`aria-label` they were given, so a listbox opened from an `aria-label`-only trigger " <>
        "(as the Cinder filters are) is still named."

  attr :anchor, :string, required: true
  attr :name, :string, required: true

  attr :groups, :list,
    required: true,
    doc: "`%{label:, options:}` maps as returned by `Options.dropdown_groups/4`."

  attr :selected?, :any, required: true, doc: "Predicate over an option's value."

  attr :input_type, :atom,
    default: :radio,
    values: [:radio, :checkbox],
    doc: "Row control. `:checkbox` renders a visible box instead of the check glyph."

  attr :multiselectable, :boolean,
    default: false,
    doc: "Renders `aria-multiselectable` on the listbox."

  attr :aria_selected, :boolean,
    default: false,
    doc:
      "Renders `aria-selected` on each option from its checked state. Multi-select needs " <>
        "this because `role=\"option\"` makes a visible checkbox presentational; the " <>
        "single-select inputs leave `aria-selected` to their hook, per the APG combobox pattern."

  attr :allow_blank, :boolean, default: false
  attr :blank_label, :string, default: nil
  attr :blank_selected, :boolean, default: false
  attr :empty_message, :string, default: nil
  attr :more_hint, :string, default: nil
  attr :option_slot, :any, default: [], doc: "The caller's `:option` slot, forwarded."

  attr :actions_slot, :any,
    default: [],
    doc:
      "Sticky action row above the options, for things like *clear selection*. Only " <>
        "`MyAppWeb.Components.Core.Inputs.multi_select/1` passes one. Supplying it moves " <>
        "`role=\"listbox\"` off the popover onto an inner `<id>-listbox` element, because a " <>
        "listbox may not contain interactive children; point `aria-controls` at that id."

  @spec listbox(map()) :: Rendered.t()
  def listbox(assigns) do
    assigns = assign(assigns, empty?: Enum.all?(assigns.groups, &(&1.options == [])))
    assigns = assign(assigns, actions?: assigns.actions_slot != [])

    # resolved here rather than as attr defaults, which compile the label in
    # whatever locale the build ran under
    assigns = assign(assigns, blank_label: assigns.blank_label || ~t"None"m)
    assigns = assign(assigns, empty_message: assigns.empty_message || ~t"No results found"m)

    ~H"""
    <div
      id={@id}
      popover="manual"
      class="combobox-dropdown"
      role={!@actions? && "listbox"}
      aria-label={!@actions? && @label}
      aria-multiselectable={!@actions? && @multiselectable && "true"}
      style={"position-anchor: #{@anchor}"}
    >
      <div :if={@actions?} class="combobox-actions">{render_slot(@actions_slot)}</div>

      <div
        :if={@actions?}
        id={"#{@id}-listbox"}
        role="listbox"
        aria-label={@label}
        aria-multiselectable={@multiselectable && "true"}
      >
        <.options_body
          id={@id}
          name={@name}
          groups={@groups}
          selected?={@selected?}
          input_type={@input_type}
          aria_selected={@aria_selected}
          allow_blank={@allow_blank}
          blank_label={@blank_label}
          blank_selected={@blank_selected}
          empty?={@empty?}
          empty_message={@empty_message}
          more_hint={@more_hint}
          option_slot={@option_slot}
        />
      </div>

      <.options_body
        :if={!@actions?}
        id={@id}
        name={@name}
        groups={@groups}
        selected?={@selected?}
        input_type={@input_type}
        aria_selected={@aria_selected}
        allow_blank={@allow_blank}
        blank_label={@blank_label}
        blank_selected={@blank_selected}
        empty?={@empty?}
        empty_message={@empty_message}
        more_hint={@more_hint}
        option_slot={@option_slot}
      />
    </div>
    """
  end

  attr :id, :string, required: true
  attr :name, :string, required: true
  attr :groups, :list, required: true
  attr :selected?, :any, required: true
  attr :input_type, :atom, required: true
  attr :aria_selected, :boolean, required: true
  attr :allow_blank, :boolean, required: true
  attr :blank_label, :string, required: true
  attr :blank_selected, :boolean, required: true
  attr :empty?, :boolean, required: true
  attr :empty_message, :string, required: true
  attr :more_hint, :string, required: true
  attr :option_slot, :any, required: true

  @spec options_body(map()) :: Rendered.t()
  defp options_body(assigns) do
    ~H"""
    <label
      :if={@allow_blank}
      id={"#{@id}-opt-blank"}
      class="combobox-option"
      role="option"
      data-label=""
    >
      <input
        type="radio"
        name={@name}
        value=""
        checked={@blank_selected}
        class="sr-only"
        tabindex="-1"
      />
      <span class="w-4 shrink-0 text-right text-sm">{if @blank_selected, do: "✓"}</span>
      <span class="text-base-content/60 flex-1 select-none text-sm">{@blank_label}</span>
    </label>

    <div
      :for={{group, gi} <- Enum.with_index(@groups)}
      role={group.label && "group"}
      aria-labelledby={group.label && "#{@id}-group-#{gi}"}
      class={group.label && "combobox-group"}
    >
      <div :if={group.label} id={"#{@id}-group-#{gi}"} class="combobox-group-label">
        {group.label}
      </div>
      <label
        :for={item <- group.options}
        id={"#{@id}-opt-#{Options.sanitize(to_string(Options.item_value(item)))}"}
        class="combobox-option"
        role="option"
        aria-selected={@aria_selected && to_string(@selected?.(Options.item_value(item)))}
        aria-disabled={Options.item_disabled(item) && "true"}
        data-disabled={Options.item_disabled(item) && "true"}
        title={Options.item_disabled_reason(item)}
        data-label={Options.item_display(item)}
      >
        <input
          type={to_string(@input_type)}
          name={@name}
          value={to_string(Options.item_value(item))}
          checked={@selected?.(Options.item_value(item))}
          disabled={Options.item_disabled(item)}
          class={if @input_type == :checkbox, do: "checkbox checkbox-sm shrink-0", else: "sr-only"}
          tabindex="-1"
        />
        <span :if={Options.item_disabled_reason(item)} class="sr-only">
          {Options.item_disabled_reason(item)}
        </span>
        <%= if @option_slot == [] do %>
          <span :if={@input_type == :radio} class="w-4 shrink-0 text-right text-sm">
            {if @selected?.(Options.item_value(item)), do: "✓"}
          </span>
          <span class="flex-1 select-none text-sm">{Options.item_label(item)}</span>
          <span
            :if={Options.item_badge(item)}
            class="badge badge-ghost badge-sm font-mono shrink-0 select-none"
          >
            {Options.item_badge(item)}
          </span>
        <% else %>
          {render_slot(@option_slot, Options.slot_arg(item, @selected?.(Options.item_value(item))))}
        <% end %>
      </label>
    </div>

    <div :if={@empty? and not @allow_blank} class="text-base-content/50 px-3 py-2 text-sm">
      {@empty_message}
    </div>

    <div :if={@more_hint} class="combobox-more">
      {@more_hint}
    </div>
    """
  end
end
