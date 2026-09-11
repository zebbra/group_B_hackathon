defmodule MyAppWeb.Components.Core.Inputs.Date do
  @moduledoc false

  use MyAppWeb, :html

  alias MyAppWeb.Components.Core.Inputs
  alias Phoenix.LiveView.Rendered

  require Inputs

  @doc """
  Renders a date input.

  ## Examples

      <Core.Inputs.date field={@form[:birthday]} label={~t"Birthday"} />

  """

  Inputs.common_attributes()

  attr :debounce, :any, default: nil

  attr :rest, :global, include: ~w(disabled form max min readonly required step)

  @spec date(map()) :: Rendered.t()
  def date(%{field: field} = assigns) when not is_nil(field) do
    assigns |> Inputs.prepare() |> date()
  end

  def date(assigns) do
    ~H"""
    <Inputs.field label={@label} errors={@errors} description={@description}>
      <input
        type="date"
        id={@id}
        name={@name}
        value={Phoenix.HTML.Form.normalize_value("date", @value)}
        phx-debounce={@debounce}
        class={[@class || "input w-full", @errors != [] && (@error_class || "input-error")]}
        {@rest}
      />
    </Inputs.field>
    """
  end
end
