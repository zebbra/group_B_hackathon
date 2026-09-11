defmodule MyAppWeb.Components.Core.Inputs.Switch do
  @moduledoc false

  use MyAppWeb, :html

  alias MyAppWeb.Components.Core.Inputs
  alias Phoenix.HTML.Form
  alias Phoenix.LiveView.Rendered

  require Inputs

  @doc """
  Renders a boolean checkbox styled as a daisyUI
  [`toggle`](https://daisyui.com/components/toggle/).

  `align` places the toggle: `:start` keeps it in front of the label, `:end`
  pushes it to the far side of the row, leaving the label at the start.

  ## Examples

      <Core.Inputs.switch field={@form[:active]} label={~t"Active"} />
      <Core.Inputs.switch field={@form[:active]} label={~t"Active"} align={:end} />

  """

  Inputs.common_attributes()

  attr :checked, :boolean, doc: "the checked flag, usually derived from the value"

  attr :align, :atom,
    default: :start,
    values: [:start, :end],
    doc: "which side of the label the toggle sits on"

  attr :rest, :global, include: ~w(disabled form required)

  @spec switch(map()) :: Rendered.t()
  def switch(%{field: field} = assigns) when not is_nil(field) do
    assigns |> Inputs.prepare() |> switch()
  end

  def switch(assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div class="fieldset">
      <label>
        <input
          type="hidden"
          name={@name}
          value="false"
          disabled={@rest[:disabled]}
          form={@rest[:form]}
        />
        <span class={["label", @align == :end && "w-full flex-row-reverse justify-between"]}>
          <input
            type="checkbox"
            id={@id}
            name={@name}
            value="true"
            checked={@checked}
            class={@class || "toggle"}
            {@rest}
          />{@label}
        </span>
      </label>
      <Inputs.errors errors={@errors} align={:left} />
      <Inputs.footer description={@description} />
    </div>
    """
  end
end
