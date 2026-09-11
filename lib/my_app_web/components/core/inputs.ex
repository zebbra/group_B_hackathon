defmodule MyAppWeb.Components.Core.Inputs do
  @moduledoc """
  This file groups all form input related components.

  ```heex
  <Core.Inputs.text field={@form[:email]} type="email" label={~t"Email"} />
  <Core.Inputs.select field={@form[:role]} label={~t"Role"} options={Role.options()} />
  <Core.Inputs.switch field={@form[:active]} label={~t"Active"} />
  ```

  All inputs accept a `Phoenix.HTML.FormField` (e.g. `@form[:email]`) via the
  `field` attr — name, id, value, and errors are derived from it — or the
  input's name as a string for non-form usage (e.g. Cinder filters). Errors
  are shown only after the input was interacted with (`used_input?/1`), are
  translated through the `errors` Gettext domain, and render in the header
  row next to the label (left-aligned below inline controls like checkboxes).
  While a field is still empty, validation is debounced until blur so users
  aren't flagged mid-typing (opt out with `validation_delayed?={false}`).
  All inputs take a `description` slot for help text below the input.

  Array-valued inputs (multi-select) always submit a hidden `""` alongside the
  checked values under `<name>[]`, so an empty selection is distinguishable
  from the field being absent from the params altogether. Consumers reading
  that param list must reject `""` rather than treat it as a real value — see
  `multi_select/1` for details.

  ## Supported inputs

  - Hidden
  - Text (and text-like types: email, password, tel, url, search, …)
  - Textarea (with optional autoresize)
  - Number
  - Select (styled, groupable `<select>` replacement over the shared listbox)
  - Combobox (searchable single-select over the shared listbox)
  - Multi-select (searchable checkbox multi-select over the shared listbox)
  - Checkbox
  - Switch (checkbox styled as toggle)
  - Radio (group)
  - File
  - Range
  - Date

  Select, combobox, and multi-select share the `Inputs.Listbox` popover and the
  `Inputs.Listbox.Options` option pipeline; see those modules for the option
  shapes and the dropdown's positioning and ARIA contract.

  For live file uploads, use `Phoenix.Component.live_file_input/1` instead of
  the file input.
  """

  use MyAppWeb, :html

  alias MyAppWeb.Components.Core.Inputs
  alias MyAppWeb.Components.Core.Utils
  alias Phoenix.HTML.FormField
  alias Phoenix.LiveView.Rendered

  @doc """
  Renders a hidden input.
  """
  @spec hidden(map()) :: Rendered.t()
  defdelegate hidden(assigns), to: Inputs.Hidden

  @doc """
  Renders a text input, or any text-like input (email, password, tel, url,
  search, …) via the `type` attr.
  """
  @spec text(map()) :: Rendered.t()
  defdelegate text(assigns), to: Inputs.Text

  @doc """
  Renders a textarea, optionally auto-resizing to fit its content.
  """
  @spec textarea(map()) :: Rendered.t()
  defdelegate textarea(assigns), to: Inputs.Textarea

  @doc """
  Renders a number input.
  """
  @spec number(map()) :: Rendered.t()
  defdelegate number(assigns), to: Inputs.Number

  @doc """
  Renders a styled, groupable replacement for a native `<select>`: a
  select-only listbox with arrow-key navigation and type-ahead, no text
  filtering.
  """
  @spec select(map()) :: Rendered.t()
  defdelegate select(assigns), to: Inputs.Select

  @doc """
  Renders a searchable single-select dropdown, for option lists too long to
  scroll through a select.
  """
  @spec combobox(map()) :: Rendered.t()
  defdelegate combobox(assigns), to: Inputs.Combobox

  @doc """
  Renders a searchable checkbox multi-select, for fields that take several
  values.
  """
  @spec multi_select(map()) :: Rendered.t()
  defdelegate multi_select(assigns), to: Inputs.MultiSelect

  @doc """
  Renders a checkbox for a boolean value.
  """
  @spec checkbox(map()) :: Rendered.t()
  defdelegate checkbox(assigns), to: Inputs.Checkbox

  @doc """
  Renders a boolean checkbox styled as a daisyUI
  [`toggle`](https://daisyui.com/components/toggle/).
  """
  @spec switch(map()) :: Rendered.t()
  defdelegate switch(assigns), to: Inputs.Switch

  @doc """
  Renders a radio group over `{label, value}` options.
  """
  @spec radio(map()) :: Rendered.t()
  defdelegate radio(assigns), to: Inputs.Radio

  @doc """
  Renders a file input. For live uploads use `Phoenix.Component.live_file_input/1`
  instead.
  """
  @spec file(map()) :: Rendered.t()
  defdelegate file(assigns), to: Inputs.File

  @doc """
  Renders a range slider.
  """
  @spec range(map()) :: Rendered.t()
  defdelegate range(assigns), to: Inputs.Range

  @doc """
  Renders a date input.
  """
  @spec date(map()) :: Rendered.t()
  defdelegate date(assigns), to: Inputs.Date

  @doc """
  Common attributes shared by all inputs.
  """
  @spec common_attributes() :: Macro.t()
  defmacro common_attributes do
    quote do
      attr :field, :any,
        required: true,
        doc:
          "a form field struct retrieved from the form (e.g. @form[:email]), or the input's " <>
            "name as a string for non-form inputs (e.g. Cinder filters)"

      attr :id, :any, default: nil, doc: "the id of the input, usually derived from the field"
      attr :name, :any, doc: "the name of the input, usually derived from the field"
      attr :label, :string, default: nil, doc: "the label of the input"
      attr :value, :any, doc: "the value of the input, usually derived from the field"

      attr :errors, :list,
        default: [],
        doc: "extra errors to show, merged with the errors derived from the field"

      attr :validation_delayed?, :boolean,
        default: true,
        doc: "while the field is empty, debounce validation until the input is blurred"

      attr :class, :any, default: nil, doc: "the input class to use over defaults"
      attr :error_class, :any, default: nil, doc: "the input error class to use over defaults"

      slot :description, doc: "help text rendered below the input"
    end
  end

  @doc """
  Normalizes assigns built from a `Phoenix.HTML.FormField`: extracts id, name,
  and value, and translates errors (shown only for used inputs). Errors passed
  via the `errors` attr are kept and shown before the field's own.

  While the field is empty (and `validation_delayed?` is left on), `debounce`
  is set to `"blur"` so typing inputs don't flag a field the user is still
  filling in for the first time.

  Every input calls this in its `field` clause before rendering.
  """
  @spec prepare(map()) :: map()
  def prepare(%{field: %FormField{} = field} = assigns) do
    field_errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns =
      assigns
      |> assign(field: nil, id: assigns.id || field.id)
      |> assign(:errors, assigns.errors ++ Enum.map(field_errors, &Utils.translate_error(&1)))
      |> assign_new(:name, fn ->
        if Map.get(assigns, :multiple, false), do: field.name <> "[]", else: field.name
      end)
      |> assign_new(:value, fn -> field.value end)

    assign(
      assigns,
      :debounce,
      Map.get(assigns, :debounce) ||
        if(empty?(assigns.value) and assigns.validation_delayed?, do: "blur")
    )
  end

  # Non-form inputs (e.g. Cinder filters) pass the input's name as a string;
  # id and value come from the caller's attrs.
  def prepare(%{field: field} = assigns) when is_binary(field) do
    assigns
    |> assign(field: nil)
    |> assign_new(:name, fn -> field end)
    |> assign_new(:value, fn -> nil end)
  end

  @doc """
  Standard wrapper for an input: fieldset with a header row above the input
  holding the optional label (left) and the errors (right-aligned).

  By default the label wraps the input. Pass `for` to associate it via the
  `for` attribute instead — required when the input itself contains `<label>`
  elements (like the listbox dropdowns), since labels cannot nest.
  """
  attr :label, :string, default: nil
  attr :errors, :list, default: []
  attr :description, :any, default: [], doc: "the input's description slot, rendered as footer"

  attr :for, :any,
    default: nil,
    doc: "id of the input the label points to; switches from wrapping to `for` association"

  slot :inner_block, required: true

  @spec field(map()) :: Rendered.t()
  def field(assigns) do
    ~H"""
    <div class="fieldset">
      <%= if @for do %>
        <div :if={@label || @errors != []} class="mb-1 flex items-end justify-between gap-4">
          <label :if={@label} for={@for} class="label">
            {@label}
          </label>
          <.errors errors={@errors} />
        </div>

        {render_slot(@inner_block)}
      <% else %>
        <label>
          <span :if={@label || @errors != []} class="mb-1 flex items-end justify-between gap-4">
            <span :if={@label} class="label">
              {@label}
            </span>
            <.errors errors={@errors} />
          </span>

          {render_slot(@inner_block)}
        </label>
      <% end %>
      <.footer description={@description} />
    </div>
    """
  end

  @doc """
  Renders the list of errors for an input, stacked and right-aligned by
  default. Use `align={:left}` for inline controls (checkbox, switch, radio).
  """
  attr :errors, :list, required: true
  attr :align, :atom, default: :right, values: [:left, :right]

  @spec errors(map()) :: Rendered.t()
  def errors(assigns) do
    ~H"""
    <span :if={@errors != []} class={["flex flex-col gap-0.5", @align == :right && "items-end"]}>
      <span :for={msg <- @errors} class="text-error text-xs">
        {msg}
      </span>
    </span>
    """
  end

  @doc """
  Renders an input's description slot as a footer below the input.
  """
  attr :description, :any, required: true

  @spec footer(map()) :: Rendered.t()
  def footer(assigns) do
    ~H"""
    <div :if={@description != []} class="pt-1 text-xs opacity-70">
      {render_slot(@description)}
    </div>
    """
  end

  @spec empty?(any()) :: boolean()
  defp empty?(nil), do: true
  defp empty?(""), do: true
  defp empty?([]), do: true
  defp empty?(_value), do: false
end
