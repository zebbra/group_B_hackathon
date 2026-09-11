defmodule MyAppWeb.Components.Core.Inputs.Select do
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
  Select-only dropdown: a styled, groupable replacement for a native `<select>`.

  Follows the APG [select-only combobox](https://www.w3.org/WAI/ARIA/apg/patterns/combobox/examples/combobox-select-only/):
  the trigger is a focusable `button`, navigated with the arrow keys, `Home`,
  `End`, and typeahead. There is no text filtering and nothing is sent to the
  server until a value is chosen. Use `MyAppWeb.Components.Core.Inputs.combobox/1`
  instead when the option list is too long to scroll.

  `id` is the base the parts are named from rather than an element of its own:
  the trigger is `-button`, the dropdown `-dropdown`. A caller labelling the
  trigger from outside points its `for` at the first of those.

  The selection is submitted as a checked radio under the field's name. Set
  `allow_blank` to offer an option that clears the field (submits `""`); the
  parent must then let the field's value be `nil`. All options are rendered —
  unlike the combobox, there is no `max_results` cap by default — and the
  dropdown is rendered by `MyAppWeb.Components.Core.Inputs.Listbox`, which
  documents its positioning and ARIA.

  A disabled option cannot be picked. When the current value is one of those,
  its radio is disabled like any other and would submit nothing, so a hidden
  input carries the value instead.

  ## Keyboard

  DOM focus always stays on the button trigger; the active option is tracked
  with `aria-activedescendant`. `ArrowDown`/`ArrowUp` open the dropdown and
  move the active option, wrapping at the ends; `Alt+ArrowDown` opens without
  moving. `Home`/`End` jump to the first/last option. `Enter` and `Space`
  select the active option, or open the dropdown (on the current selection)
  when it is closed. Typing a printable character does type-ahead: it matches
  the start of an option's label, resetting after a short pause between
  keystrokes. `Escape` and `Tab` close the dropdown.

  ## Examples

      <Core.Inputs.select
        field={@form[:role]}
        label={~t"Role"}
        options={[{"Admin", "admin"}, {"User", "user"}]}
      />

  """

  Inputs.common_attributes()
  Listbox.option_attributes()

  attr :placeholder, :string, default: nil
  attr :rest, :global

  @spec select(map()) :: Rendered.t()
  def select(%{field: field} = assigns) when not is_nil(field) do
    assigns |> Inputs.prepare() |> select()
  end

  def select(assigns) do
    assigns = assign(assigns, id: Options.base_id(assigns.id, assigns.name))
    value = assigns.value
    selected? = &Options.same?(&1, value)

    {groups, _visible, _has_more?} =
      Options.dropdown_groups(assigns.options, nil, assigns.max_results, selected?)

    assigns =
      assigns
      |> assign(render_groups: groups)
      |> assign(selected_label: Options.display_of(assigns.options, value))
      |> assign(carry_selection?: disabled_selection?(assigns.options, value))
      |> assign(dropdown_id: "#{assigns.id}-dropdown")
      |> assign(listbox_label: assigns.label || Map.get(assigns.rest, :"aria-label"))
      |> assign(anchor: "--#{assigns.id}-anchor")

    ~H"""
    <Inputs.field for={"#{@id}-button"} label={@label} errors={@errors} description={@description}>
      <div
        id={"#{@id}-select"}
        class="relative"
        phx-hook=".Select"
        data-placeholder={@placeholder}
      >
        <div class="contents">
          <input :if={@carry_selection?} type="hidden" name={@name} value={@value} />
        </div>

        <button
          type="button"
          id={"#{@id}-button"}
          role="combobox"
          aria-haspopup="listbox"
          aria-expanded="false"
          aria-controls={@dropdown_id}
          phx-mounted={JS.ignore_attributes(["aria-expanded"])}
          style={"anchor-name: #{@anchor}"}
          class={["input flex w-full cursor-pointer items-center pr-7 text-left", @errors != [] && (@error_class || "input-error"), @class]}
          {@rest}
        >
          <span class={["combobox-value flex-1 truncate", @selected_label == nil && "combobox-placeholder"]}>
            {@selected_label || @placeholder}
          </span>
        </button>

        <span class="combobox-caret" aria-hidden="true" />

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
          option_slot={@option}
        />
      </div>
    </Inputs.field>

    <script :type={ColocatedHook} name=".Select" extension="ts">
      import * as Listbox from "@/js/listbox";
      import { ViewHook } from "phoenix_live_view";

      export default class extends ViewHook {
        declare dropdown: HTMLElement;
        declare input: HTMLElement;
        declare valueEl: HTMLElement;
        declare caret: HTMLElement;
        declare typeaheadBuffer: string;
        declare typeaheadTimer: ReturnType<typeof setTimeout>;

        mounted() {
          this.dropdown = this.el.querySelector<HTMLElement>(".combobox-dropdown")!;
          this.input = this.el.querySelector<HTMLElement>('[role="combobox"]')!;
          this.valueEl = this.el.querySelector<HTMLElement>(".combobox-value")!;
          this.caret = this.el.querySelector<HTMLElement>(".combobox-caret")!;

          this.dropdown.addEventListener("mousedown", (e) => e.preventDefault());

          this.el.addEventListener("click", (e) => {
            const target = e.target as HTMLElement;
            const option = target.closest<HTMLElement>(".combobox-option");
            if (option) {
              // the radio is already disabled; this only stops the trigger's text from following
              if (option.dataset.disabled) return e.preventDefault();

              return this.select(option);
            }

            if (target.closest('[role="combobox"]')) {
              this.toggle();
              this.input.focus();
              Listbox.deactivate(this.input, this.dropdown);
            }
          });

          this.input.addEventListener("keydown", (e) => this.onKeydown(e));

          this.el.addEventListener("focusout", (e) => {
            if (!this.el.contains(e.relatedTarget as Node)) this.hide();
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
            case " ":
              e.preventDefault();
              if (Listbox.isOpen(this.dropdown)) {
                const active = Listbox.activeOption(this.input, this.dropdown);
                if (active) active.click();
                else this.hide();
              } else {
                this.show();
                Listbox.activate(this.input, this.dropdown, Listbox.checkedIndex(this.dropdown));
              }
              break;

            case "Escape":
              if (Listbox.isOpen(this.dropdown)) e.stopPropagation();
              this.hide();
              break;

            case "Tab":
              if (Listbox.isOpen(this.dropdown)) this.hide();
              break;

            case "Home":
            case "End":
              e.preventDefault();
              this.show();
              Listbox.activate(
                this.input,
                this.dropdown,
                e.key === "Home" ? 0 : Listbox.lastIndex(this.dropdown),
              );
              break;

            default:
              if (this.isTypeahead(e)) {
                e.preventDefault();
                this.typeahead(e.key);
              }
              break;
          }
        }

        isTypeahead(e: KeyboardEvent): boolean {
          return !e.ctrlKey && !e.metaKey && !e.altKey && e.key.length === 1 && /\S/.test(e.key);
        }

        typeahead(char: string): void {
          clearTimeout(this.typeaheadTimer);
          this.typeaheadBuffer = (this.typeaheadBuffer || "") + char.toLowerCase();
          this.typeaheadTimer = setTimeout(() => {
            this.typeaheadBuffer = "";
          }, 500);

          const opts = Listbox.options(this.dropdown);
          const match = opts.find((o) =>
            (o.dataset.label || "").toLowerCase().startsWith(this.typeaheadBuffer),
          );
          if (match) {
            this.show();
            Listbox.activate(this.input, this.dropdown, opts.indexOf(match));
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
          this.caret.classList.toggle("rotate-180", state);
        }

        select(option: HTMLElement): void {
          this.valueEl.textContent = option.dataset.label || this.el.dataset.placeholder || "";
          this.valueEl.classList.toggle("combobox-placeholder", !option.dataset.label);
          this.hide();
          this.input.focus();
        }
      }
    </script>
    """
  end

  @spec disabled_selection?(list(), any()) :: boolean()
  defp disabled_selection?(options, value) do
    case Options.find_option(options, value) do
      nil -> false
      item -> Options.item_disabled(item)
    end
  end
end
