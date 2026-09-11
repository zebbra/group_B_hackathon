defmodule MyAppWeb.Components.Core.Inputs.Combobox do
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
  Searchable single-select dropdown for form fields whose option list is too
  large for a select (e.g. picking one company out of hundreds).

  The user types to filter a static option list, picks from a dropdown, and the
  choice is submitted under the form field's name.

  ## Behaviour

    * **Value** — the selection is submitted as a checked radio under the
      field's name. When it is filtered out of the visible options, a hidden
      input carries it instead, so the form value survives narrowing; that input
      sits in its own wrapper, which keeps its appearing and disappearing from
      shifting the trigger or the popover. Set `allow_blank` to add a blank
      option that clears the field (submits `""`); the parent must then let the
      field's value be `nil`.
    * **Options** — a flat list of options, or groups to render `<optgroup>`-style
      sections; each group's options are filtered independently and empty groups
      are dropped. See `MyAppWeb.Components.Core.Inputs.Listbox.option_attributes/0`
      for the accepted shapes. A disabled option cannot be picked; when the
      current value is one of those, the same hidden input carries it, since its
      radio is disabled and would submit nothing.
    * **Search** — the search box reports under `search_name`, deliberately
      outside the form's param namespace so form validation never sees it. The
      parent LiveView owns the term (`search_term`) and does the filtering.
      Selecting clears the term as a side effect: the radio's `change` posts the
      trigger, holding the option's label by then, and the server suppresses a
      term equal to the selection's own display. Re-picking the option that is
      already selected fires no `change`, so the hook resets the search itself.
      The search input pushes `search_event` (or, when nil, the enclosing form's
      change event) and debounces on `:debounce` ms (default 300).
    * **Visible options** — capped by `max_results` (default 10), the rest
      surfacing as you narrow the search; see
      `MyAppWeb.Components.Core.Inputs.Listbox.Options` for how the cap treats
      the current selection.
    * **Keyboard** (colocated `Combobox` hook) — DOM focus always stays in the
      input. Typing or clicking opens the dropdown; `ArrowDown`/`ArrowUp` (and
      `Alt+ArrowDown`) open it and move the active option, tracked with
      `aria-activedescendant` and wrapping at the ends. `Enter` selects the active
      option; `Home`, `End`, `ArrowLeft`, and `ArrowRight` return visual focus to
      the input for text editing. Leaving the field — `Tab`, `Escape`, or clicking
      away — closes the dropdown, restores the input to the current selection, and
      discards an unfinished search. Only a listed option (or nothing) is ever
      committed; the typed text is never submitted.
    * **ARIA** — follows the [combobox pattern](https://www.w3.org/WAI/ARIA/apg/patterns/combobox/):
      the input is a `combobox` with `aria-autocomplete="list"`, `aria-controls`,
      `aria-expanded` (toggled on open/close), and `aria-activedescendant`. The
      dropdown's own ARIA contract belongs to `MyAppWeb.Components.Core.Inputs.Listbox`.

  ## Examples

      <Core.Inputs.combobox
        field={@form[:company_id]}
        label={~t"Company"}
        options={Enum.map(@companies, &{&1.name, &1.id})}
        search_name="company_search"
        search_term={@company_search}
        placeholder={~t"Search companies…"}
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

  @spec combobox(map()) :: Rendered.t()
  def combobox(%{field: field} = assigns) when not is_nil(field) do
    assigns |> Inputs.prepare() |> combobox()
  end

  def combobox(assigns) do
    assigns = assign(assigns, max_results: assigns.max_results || 10)
    assigns = assign(assigns, id: Options.base_id(assigns.id, assigns.name))
    value = assigns.value
    selected? = &Options.same?(&1, value)

    {groups, filtered, has_more?} =
      Options.dropdown_groups(
        assigns.options,
        assigns.search_term,
        assigns.max_results,
        selected?
      )

    assigns =
      assigns
      |> assign(render_groups: groups)
      |> assign(has_more?: has_more?)
      |> assign(selected_label: Options.display_of(assigns.options, value))
      |> assign(selection_visible?: Enum.any?(filtered, &submittable?(&1, selected?)))
      |> assign(dropdown_id: "#{assigns.id}-dropdown")
      |> assign(listbox_label: assigns.label || Map.get(assigns.rest, :"aria-label"))
      |> assign(anchor: "--#{assigns.id}-anchor")

    ~H"""
    <Inputs.field for={@id} label={@label} errors={@errors} description={@description}>
      <div
        id={"#{@id}-combobox"}
        class="relative"
        phx-hook=".Combobox"
        data-search-event={@search_event}
        data-selected-label={@selected_label}
      >
        <div class="contents">
          <input
            :if={@value not in [nil, ""]}
            type="hidden"
            name={@name}
            value={@value}
            disabled={@selection_visible?}
          />
        </div>

        <input
          type="text"
          id={@id}
          name={@search_name}
          value={@selected_label || @search_term}
          placeholder={@placeholder}
          autocomplete="off"
          role="combobox"
          aria-autocomplete="list"
          aria-haspopup="listbox"
          aria-expanded="false"
          aria-controls={@dropdown_id}
          phx-mounted={JS.ignore_attributes(["aria-expanded"])}
          phx-change={@search_event}
          phx-debounce={@debounce}
          style={"anchor-name: #{@anchor}"}
          class={["input w-full cursor-pointer pr-7", @errors != [] && (@error_class || "input-error"), @class]}
          {@rest}
        />

        <button
          type="button"
          id={"#{@id}-button"}
          class="combobox-button"
          tabindex="-1"
          aria-label={@label || ~t"Toggle options"m}
          aria-controls={@dropdown_id}
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
          selected?={&Options.same?(&1, @value)}
          allow_blank={@allow_blank}
          blank_label={@blank_label}
          blank_selected={@value in [nil, ""]}
          more_hint={if @has_more?, do: ~t"Type to search more options…"m}
          option_slot={@option}
        />
      </div>
    </Inputs.field>

    <script :type={ColocatedHook} name=".Combobox" extension="ts">
      import * as Listbox from "@/js/listbox";
      import { ViewHook } from "phoenix_live_view";

      export default class extends ViewHook {
        declare dropdown: HTMLElement;
        declare input: HTMLInputElement;
        declare button: HTMLElement;
        declare caret: HTMLElement;
        declare resetting: boolean;

        mounted() {
          this.dropdown = this.el.querySelector<HTMLElement>(".combobox-dropdown")!;
          this.input = this.el.querySelector<HTMLInputElement>('[role="combobox"]')!;
          this.button = this.el.querySelector<HTMLElement>(".combobox-button")!;
          this.caret = this.el.querySelector<HTMLElement>(".combobox-caret")!;

          this.dropdown.addEventListener("mousedown", (e) => e.preventDefault());

          this.input.addEventListener("input", () => {
            if (this.resetting) return;
            this.show();
            Listbox.deactivate(this.input, this.dropdown);
          });

          this.button.addEventListener("mousedown", (e) => e.preventDefault());
          this.button.addEventListener("click", () => {
            this.toggle();
            this.input.focus();
            this.selectLabel();
            Listbox.deactivate(this.input, this.dropdown);
          });

          this.el.addEventListener("click", (e) => {
            const target = e.target as HTMLElement;
            const option = target.closest<HTMLElement>(".combobox-option");
            if (option) {
              // the radio is already disabled; this only stops the input's text from following
              if (option.dataset.disabled) return e.preventDefault();

              return this.select(option);
            }

            if (target.closest('[role="combobox"]')) {
              this.show();
              this.input.focus();
              this.selectLabel();
              Listbox.deactivate(this.input, this.dropdown);
            }
          });

          this.input.addEventListener("keydown", (e) => this.onKeydown(e));

          this.el.addEventListener("focusout", (e) => {
            if (!this.el.contains(e.relatedTarget as Node)) this.revert();
          });
        }

        updated() {
          if (Listbox.isOpen(this.dropdown)) Listbox.deactivate(this.input, this.dropdown);
        }

        onKeydown(e: KeyboardEvent): void {
          switch (e.key) {
            case "ArrowDown":
              e.preventDefault();
              this.show();
              if (e.altKey) break;
              if (Listbox.listboxFocused(this.input)) Listbox.move(this.input, this.dropdown, 1);
              else Listbox.activate(this.input, this.dropdown, Listbox.checkedIndex(this.dropdown));
              break;

            case "ArrowUp":
              e.preventDefault();
              this.show();
              if (Listbox.listboxFocused(this.input)) Listbox.move(this.input, this.dropdown, -1);
              else Listbox.activate(this.input, this.dropdown, Listbox.lastIndex(this.dropdown));
              break;

            case "Enter":
              e.preventDefault();
              if (Listbox.isOpen(this.dropdown)) {
                const active = Listbox.activeOption(this.input, this.dropdown);
                if (active) active.click();
                else this.revert();
              }
              break;

            case "Escape":
              if (Listbox.isOpen(this.dropdown)) e.stopPropagation();
              this.revert();
              break;

            case "Tab":
              if (Listbox.isOpen(this.dropdown)) {
                const active = Listbox.activeOption(this.input, this.dropdown);
                if (active) active.click();
                else this.revert();
              }
              break;

            case "Home":
            case "End":
              Listbox.deactivate(this.input, this.dropdown);
              break;

            case "ArrowLeft":
            case "ArrowRight":
              Listbox.deactivate(this.input, this.dropdown);
              break;
          }
        }

        toggle(): void {
          if (Listbox.isOpen(this.dropdown)) this.hide();
          else this.show();
        }

        show(): void {
          if (!Listbox.isOpen(this.dropdown)) this.dropdown.showPopover();
          this.expanded(true);
        }

        hide(): void {
          Listbox.deactivate(this.input, this.dropdown);
          if (Listbox.isOpen(this.dropdown)) this.dropdown.hidePopover();
          this.expanded(false);
        }

        expanded(state: boolean): void {
          this.input.setAttribute("aria-expanded", String(state));
          this.button.setAttribute("aria-expanded", String(state));
          this.caret.classList.toggle("rotate-180", state);
        }

        select(option: HTMLElement): void {
          const box = option.querySelector("input");
          const reselected = !!box && box.checked;

          this.setDisplay(option.dataset.label!);
          this.hide();
          this.input.focus();
          this.input.select();

          if (reselected) this.resetSearch();
        }

        setDisplay(label: string): void {
          this.input.value = label;
        }

        revert(): void {
          const pending = this.input.value !== (this.el.dataset.selectedLabel || "");
          this.hide();
          this.restoreLabel();
          if (pending) this.resetSearch();
        }

        restoreLabel(): void {
          this.input.value = this.el.dataset.selectedLabel || "";
        }

        selectLabel(): void {
          if (this.input.value === (this.el.dataset.selectedLabel || "")) this.input.select();
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

  @spec submittable?(Options.option(), (any() -> boolean())) :: boolean()
  defp submittable?(item, selected?) do
    selected?.(Options.item_value(item)) and not Options.item_disabled(item)
  end
end
