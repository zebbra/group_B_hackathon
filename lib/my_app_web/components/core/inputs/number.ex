defmodule MyAppWeb.Components.Core.Inputs.Number do
  @moduledoc false

  use MyAppWeb, :html

  alias MyAppWeb.Components.Core.Inputs
  alias Phoenix.LiveView.Rendered

  require Inputs

  @doc """
  Renders a number input.

  Rendered as `type="text"` with `inputmode`, not `type="number"`
  https://hexdocs.pm/phoenix_live_view/form-bindings.html#number-inputs).

  ## Examples

      <Core.Inputs.number field={@form[:age]} label={~t"Age"} pattern="[0-9]*" />
      <Core.Inputs.number field={@form[:price]} label={~t"Price"} inputmode="decimal" />

  """

  Inputs.common_attributes()

  attr :debounce, :any, default: nil
  attr :inputmode, :string, default: "numeric", values: ~w(numeric decimal)

  attr :rest, :global, include: ~w(disabled form maxlength minlength pattern placeholder readonly required)

  @spec number(map()) :: Rendered.t()
  def number(%{field: field} = assigns) when not is_nil(field) do
    assigns |> Inputs.prepare() |> number()
  end

  def number(assigns) do
    ~H"""
    <Inputs.field label={@label} errors={@errors} description={@description}>
      <input
        type="text"
        inputmode={@inputmode}
        id={@id}
        name={@name}
        value={Phoenix.HTML.Form.normalize_value("text", @value)}
        phx-debounce={@debounce}
        class={[@class || "input w-full", @errors != [] && (@error_class || "input-error")]}
        {@rest}
      />
    </Inputs.field>
    """
  end
end
