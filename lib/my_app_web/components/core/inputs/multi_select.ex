defmodule MyAppWeb.Components.Core.Inputs.MultiSelect do
  @moduledoc false

  use MyAppWeb, :html

  alias MyAppWeb.Components.Core.Inputs
  alias MyAppWeb.Components.Core.Inputs.Listbox
  alias MyAppWeb.Components.Core.Inputs.Listbox.Options
  alias Phoenix.LiveView.ColocatedHook
  alias Phoenix.LiveView.Rendered

  require Inputs
  require Listbox

  @doc ~S"""
  Searchable checkbox multi-select for fields that take several values.

  The searchable sibling of `MyAppWeb.Components.Core.Inputs.select/1` and
  `MyAppWeb.Components.Core.Inputs.combobox/1`, sharing their popover
  (`MyAppWeb.Components.Core.Inputs.Listbox`) and option pipeline.

  ## Behaviour

    * **Value** — a list, submitted as checked checkboxes under `<name>[]`. A
      hidden empty value is always submitted so clearing every box is
      distinguishable from the field being absent; consumers must reject `""`.
      A selected value the search term has filtered out of view is carried by
      its own hidden input, so narrowing the search never discards a selection.
      Those inputs sit in their own wrapper, which keeps their changing count
      from shifting the trigger or the popover.
    * **Disabled options** cannot be toggled. A selected one still shows as
      checked and rides in a hidden input like a filtered-out selection, since a
      disabled checkbox submits nothing; only the `:actions` row can clear it.
    * **Trigger** — the input's *value* is the search term and nothing else; the
      selection summary rides in the *placeholder*, styled like input text so it
      does not read as a hint. It shows the single option's display when one is
      selected and `"N selected"` beyond that, giving way to the term as soon as
      one is typed.
    * **Search** — as for the combobox: the input reports under `search_name`,
      outside the form's param namespace, and the parent LiveView owns the term
      and does the filtering.
    * **Visible options** — capped by `max_results` (default 10); see
      `MyAppWeb.Components.Core.Inputs.Listbox.Options` for how the cap treats
      the current selection.
    * **Selection does not close the dropdown**, by click or by `Enter`. A click
      anywhere on the row *except* the box itself is taken over: label activation
      is cancelled and the checkbox toggled directly, so clicking the label
      behaves exactly like clicking the box and focus never moves into the
      popover.
    * **Closing** discards the search term. A click outside reverts on
      `mousedown`, not on `focusout`: the browser commits an edited input with a
      native `change` *before* `focusout` runs, so reverting later would post the
      stale term undebounced. `Escape` never blurs and `Tab` reverts on
      `keydown`, so both already commit the cleared value.
    * **Announcing the selection** — the summary is a placeholder, so a visually
      hidden `aria-describedby` target repeats it and the selection is announced
      from the closed control rather than only by opening the listbox.
    * **ARIA** — follows the multi-select listbox pattern: `aria-multiselectable`
      on the listbox and `aria-selected` rendered from the checked state, since
      `role="option"` makes the visible checkbox presentational. The active
      option is conveyed by `aria-activedescendant` and `.is-active` alone.

  `allow_blank` and `blank_label` are accepted, via `Listbox.option_attributes/0`,
  for signature compatibility with `select/1` and `combobox/1`, but have no
  effect here: clearing every checkbox is already the empty state for a
  multi-select, so a blank option would be meaningless.

  ## Examples

      <Core.Inputs.multi_select
        field={@form[:role_ids]}
        label={~t"Roles"}
        options={@roles}
        search_name="role_search"
        search_term={@role_search}
        placeholder={~t"Search roles…"}
      />

  """

  Inputs.common_attributes()
  Listbox.option_attributes()

  attr :search_name, :string, default: nil
  attr :search_term, :string, default: ""
  attr :search_event, :string, default: nil
  attr :placeholder, :string, default: nil
  attr :debounce, :integer, default: 300

  attr :rest, :global

  slot :actions,
    doc:
      "Sticky row above the options, for actions over the selection as a whole. Clicking it " <>
        "keeps the dropdown open and the trigger focused, so a control here should clear " <>
        "through the owning LiveView rather than by unchecking boxes: a selection the search " <>
        "term hides lives in a hidden input, not a checkbox. Mark a control with " <>
        "`data-clears-search` when its handler also resets `search_term` server-side — the " <>
        "trigger keeps focus, and LiveView will not overwrite a focused input's value, so the " <>
        "box would otherwise keep showing a term that no longer filters anything."

  @spec multi_select(map()) :: Rendered.t()
  def multi_select(%{field: field} = assigns) when not is_nil(field) do
    assigns |> Inputs.prepare() |> multi_select()
  end

  def multi_select(assigns) do
    assigns = assign(assigns, max_results: assigns.max_results || 10)
    assigns = assign(assigns, id: Options.base_id(assigns.id, assigns.name))
    assigns = assign(assigns, name: array_name(assigns.name))

    selected = selected_values(assigns.value)
    selected? = &(to_string(&1) in selected)

    {groups, visible, has_more?} =
      Options.dropdown_groups(
        assigns.options,
        assigns.search_term,
        assigns.max_results,
        selected?
      )

    rendered =
      visible
      |> Enum.reject(&Options.item_disabled/1)
      |> MapSet.new(&to_string(Options.item_value(&1)))

    assigns =
      assigns
      |> assign(render_groups: groups)
      |> assign(has_more?: has_more?)
      |> assign(selected?: selected?)
      |> assign(carried: Enum.reject(selected, &MapSet.member?(rendered, &1)))
      |> assign(display: display(assigns.options, selected))
      |> assign(dropdown_id: "#{assigns.id}-dropdown")
      |> assign(
        listbox_id:
          if(assigns.actions == [],
            do: "#{assigns.id}-dropdown",
            else: "#{assigns.id}-dropdown-listbox"
          )
      )
      |> assign(listbox_label: assigns.label || Map.get(assigns.rest, :"aria-label"))
      |> assign(anchor: "--#{assigns.id}-anchor")

    ~H"""
    <Inputs.field for={@id} label={@label} errors={@errors} description={@description}>
      <div
        id={"#{@id}-multi-select"}
        class="relative"
        phx-hook=".MultiSelect"
        data-search-event={@search_event}
      >
        <div class="contents">
          <input type="hidden" name={@name} value="" />
          <input :for={value <- @carried} type="hidden" name={@name} value={value} />
        </div>

        <span id={"#{@id}-summary"} class="sr-only">{@display}</span>

        <input
          type="text"
          id={@id}
          name={@search_name}
          value={@search_term}
          placeholder={@display || @placeholder}
          autocomplete="off"
          role="combobox"
          aria-autocomplete="list"
          aria-haspopup="listbox"
          aria-expanded="false"
          aria-controls={@listbox_id}
          aria-describedby={@display && "#{@id}-summary"}
          phx-mounted={JS.ignore_attributes(["aria-expanded"])}
          phx-change={@search_event}
          phx-debounce={@debounce}
          style={"anchor-name: #{@anchor}"}
          class={["input w-full cursor-pointer pr-7", @display && "placeholder:text-base-content placeholder:opacity-100", @errors != [] && (@error_class || "input-error"), @class]}
          {@rest}
        />

        <button
          type="button"
          id={"#{@id}-button"}
          class="combobox-button"
          tabindex="-1"
          aria-label={@label || ~t"Toggle options"m}
          aria-controls={@listbox_id}
          aria-expanded="false"
          phx-mounted={JS.ignore_attributes(["aria-expanded"])}
        >
          <span class="combobox-caret" aria-hidden="true" />
        </button>

        <Listbox.listbox
          id={@dropdown_id}
          label={@listbox_label}
          anchor={@anchor}
          name={@name}
          groups={@render_groups}
          selected?={@selected?}
          input_type={:checkbox}
          multiselectable
          aria_selected
          more_hint={if @has_more?, do: ~t"Type to search more options…"m}
          option_slot={@option}
          actions_slot={@actions}
        />
      </div>
    </Inputs.field>

    <script :type={ColocatedHook} name=".MultiSelect" extension="ts">
      import * as Listbox from "@/js/listbox";
      import { ViewHook } from "phoenix_live_view";

      export default class extends ViewHook {
        declare dropdown: HTMLElement;
        declare input: HTMLInputElement;
        declare button: HTMLElement;
        declare caret: HTMLElement;
        declare resetting: boolean;
        declare activeId: string | null;
        declare pinned: string[] | null;
        declare onOutsideMousedown: (e: MouseEvent) => void;

        mounted() {
          this.dropdown = this.el.querySelector<HTMLElement>(".combobox-dropdown")!;
          this.input = this.el.querySelector<HTMLInputElement>('[role="combobox"]')!;
          this.button = this.el.querySelector<HTMLElement>(".combobox-button")!;
          this.caret = this.el.querySelector<HTMLElement>(".combobox-caret")!;

          this.dropdown.addEventListener("mousedown", (e) => e.preventDefault());
          this.dropdown.addEventListener("click", (e) => {
            const target = e.target as HTMLElement;
            if (target.closest("[data-clears-search]")) this.input.value = "";
            else this.onLabelClick(e);
          });

          this.input.addEventListener("input", () => {
            if (this.resetting) return;
            this.show();
            this.clearActive();
          });

          this.button.addEventListener("mousedown", (e) => e.preventDefault());
          this.button.addEventListener("click", () => {
            this.toggle();
            this.input.focus();
            if (this.open()) this.input.select();
            this.clearActive();
          });

          this.el.addEventListener("click", (e) => {
            const target = e.target as HTMLElement;
            if (target.closest(".combobox-option")) return;

            if (target.closest('[role="combobox"]')) {
              const wasOpen = this.open();
              this.show();
              this.input.focus();
              if (!wasOpen) this.input.select();
              this.clearActive();
            }
          });

          this.input.addEventListener("keydown", (e) => this.onKeydown(e));

          this.el.addEventListener("focusout", (e) => {
            if (!this.el.contains(e.relatedTarget as Node)) this.revert();
          });

          this.onOutsideMousedown = (e) => {
            if (this.el.contains(e.target as Node)) return;
            if (!this.open() && this.input.value === "") return;

            this.revert();
          };

          document.addEventListener("mousedown", this.onOutsideMousedown, true);
        }

        destroyed() {
          document.removeEventListener("mousedown", this.onOutsideMousedown, true);
        }

        updated() {
          if (!this.open()) return;

          const id = this.activeId;
          this.pin();

          if (id) this.restoreActive(id);
          else this.clearActive();
        }

        onKeydown(e: KeyboardEvent): void {
          switch (e.key) {
            case "ArrowDown":
              e.preventDefault();
              this.show();
              if (e.altKey) break;
              if (this.listboxFocused()) this.move(1);
              else this.setActive(Listbox.checkedIndex(this.dropdown));
              break;

            case "ArrowUp":
              e.preventDefault();
              this.show();
              if (this.listboxFocused()) this.move(-1);
              else this.setActive(Listbox.lastIndex(this.dropdown));
              break;

            case "Enter":
              e.preventDefault();
              if (this.open()) {
                const active = Listbox.activeOption(this.input, this.dropdown);
                if (active) active.click();
              }
              break;

            case "Escape":
              if (this.open()) e.stopPropagation();
              this.revert();
              break;

            case "Tab":
              if (this.open()) this.revert();
              break;

            case "Home":
            case "End":
            case "ArrowLeft":
            case "ArrowRight":
              this.clearActive();
              break;
          }
        }

        // every checkbox in the popover sits in a label: the option rows and the
        // :actions row alike. Native label activation would focus the box it
        // belongs to, so the click is taken over for both.
        onLabelClick(e: MouseEvent): void {
          const label = (e.target as Element).closest<HTMLElement>("label");
          if (!label) return;

          // the box is already disabled, but the toggle below would move it anyway
          if (label.dataset.disabled) return;

          const box = label.querySelector("input") as HTMLInputElement | null;
          if (!box) return;

          if (e.target !== box) {
            e.preventDefault();
            box.checked = !box.checked;
            box.dispatchEvent(new Event("input", { bubbles: true }));
            box.dispatchEvent(new Event("change", { bubbles: true }));
          }

          this.input.focus();
          this.input.select();
        }

        open(): boolean {
          return Listbox.isOpen(this.dropdown);
        }

        listboxFocused(): boolean {
          return Listbox.listboxFocused(this.input);
        }

        toggle(): void {
          if (this.open()) this.hide();
          else this.show();
        }

        show(): void {
          const wasOpen = this.open();
          if (!wasOpen) this.dropdown.showPopover();
          this.expanded(true);

          if (!wasOpen) {
            this.capturePinned();
            this.pin();
          }
        }

        hide(): void {
          this.clearActive();
          if (this.open()) this.dropdown.hidePopover();
          this.expanded(false);
          this.pinned = null;
        }

        expanded(state: boolean): void {
          this.input.setAttribute("aria-expanded", String(state));
          this.button.setAttribute("aria-expanded", String(state));
          this.caret.classList.toggle("rotate-180", state);
        }

        setActive(index: number): void {
          const opt = Listbox.setActive(this.input, this.dropdown, index);
          this.activeId = opt ? opt.id : null;
        }

        clearActive(): void {
          Listbox.clearActive(this.input, this.dropdown);
          this.activeId = null;
        }

        move(delta: number): void {
          const opts = Listbox.options(this.dropdown);
          if (!opts.length) return;

          const current = opts.indexOf(Listbox.activeOption(this.input, this.dropdown)!);
          this.setActive(Listbox.nextIndex(current, delta, opts.length));
        }

        restoreActive(id: string): void {
          const index = Listbox.options(this.dropdown).findIndex((o) => o.id === id);
          if (index < 0) this.clearActive();
          else this.setActive(index);
        }

        capturePinned(): void {
          // allOptions: a checked-but-disabled row is pinned like any other, so it
          // does not jump around the list it cannot be unchecked from
          this.pinned = Listbox.allOptions(this.dropdown).flatMap((o) => {
            const box = o.querySelector("input");
            return box?.checked ? [box.value] : [];
          });
        }

        pin(): void {
          const pinned = this.pinned;
          if (!pinned || !pinned.length) return;

          const byContainer = new Map<Element, Element[]>();

          Listbox.allOptions(this.dropdown).forEach((o) => {
            const input = o.querySelector("input");
            const container = o.parentElement;
            if (!input || !container || !pinned.includes(input.value)) return;

            const rows = byContainer.get(container) || [];
            rows.push(o);
            byContainer.set(container, rows);
          });

          byContainer.forEach((rows, container) => {
            const anchor = Array.from(container.children).find(
              (child) => child.classList.contains("combobox-option") && !rows.includes(child),
            );
            if (!anchor) return;

            rows.forEach((row) => container.insertBefore(row, anchor));
          });
        }

        revert(): void {
          const pending = this.input.value !== "";
          this.hide();
          this.input.value = "";
          if (pending) this.resetSearch();
        }

        resetSearch(): void {
          const event = this.el.dataset.searchEvent;
          if (event) {
            this.pushEvent(event, { [this.input.name]: "" });
          } else {
            this.resetting = true;
            this.input.dispatchEvent(new Event("input", { bubbles: true }));
            this.resetting = false;
          }
        }
      }
    </script>
    """
  end

  @spec array_name(String.t()) :: String.t()
  defp array_name(name) do
    if String.ends_with?(name, "[]"), do: name, else: name <> "[]"
  end

  @spec selected_values(any()) :: [String.t()]
  defp selected_values(value) do
    value
    |> List.wrap()
    |> Enum.map(&to_string/1)
    |> Enum.reject(&(&1 == ""))
  end

  @spec display(list(), [String.t()]) :: String.t() | nil
  defp display(_options, []), do: nil
  defp display(options, [value]), do: Options.display_of(options, value)
  defp display(_options, values), do: "#{length(values)} selected"
end
