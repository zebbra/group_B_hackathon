defmodule MyAppWeb.Components.Core.Inputs.Checkbox do
  @moduledoc false

  use MyAppWeb, :html

  alias MyAppWeb.Components.Core.Inputs
  alias Phoenix.HTML.Form
  alias Phoenix.LiveView.Rendered

  require Inputs

  @doc """
  Renders a checkbox for a boolean value.

  ## Examples

      <Core.Inputs.checkbox field={@form[:accepted]} label={~t"Accept the terms"} />

  """

  Inputs.common_attributes()

  attr :checked, :boolean, doc: "the checked flag, usually derived from the value"
  attr :rest, :global, include: ~w(disabled form required)

  @spec checkbox(map()) :: Rendered.t()
  def checkbox(%{field: field} = assigns) when not is_nil(field) do
    assigns |> Inputs.prepare() |> checkbox()
  end

  def checkbox(assigns) do
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
        <span class="label">
          <input
            type="checkbox"
            id={@id}
            name={@name}
            value="true"
            checked={@checked}
            class={@class || "checkbox checkbox-sm"}
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
