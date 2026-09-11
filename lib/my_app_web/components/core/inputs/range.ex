defmodule MyAppWeb.Components.Core.Inputs.Range do
  @moduledoc false

  use MyAppWeb, :html

  alias MyAppWeb.Components.Core.Inputs
  alias Phoenix.LiveView.Rendered

  require Inputs

  @doc """
  Renders a range slider.

  ## Examples

      <Core.Inputs.range field={@form[:volume]} label={~t"Volume"} min="0" max="100" />

  """

  Inputs.common_attributes()

  attr :rest, :global, include: ~w(disabled form list max min required step)

  @spec range(map()) :: Rendered.t()
  def range(%{field: field} = assigns) when not is_nil(field) do
    assigns |> Inputs.prepare() |> range()
  end

  def range(assigns) do
    ~H"""
    <Inputs.field label={@label} errors={@errors} description={@description}>
      <input
        type="range"
        id={@id}
        name={@name}
        value={Phoenix.HTML.Form.normalize_value("range", @value)}
        class={@class || "range w-full"}
        {@rest}
      />
    </Inputs.field>
    """
  end
end
