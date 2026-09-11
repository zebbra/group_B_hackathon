defmodule MyAppWeb.Components.Core.Inputs.Text do
  @moduledoc false

  use MyAppWeb, :html

  alias MyAppWeb.Components.Core.Inputs
  alias Phoenix.LiveView.Rendered

  require Inputs

  @doc """
  Renders a text input, or any text-like input via the `type` attr.

  ## Examples

      <Core.Inputs.text field={@form[:name]} label={~t"Name"} />
      <Core.Inputs.text field={@form[:email]} type="email" label={~t"Email"} />

  """

  Inputs.common_attributes()

  attr :type, :string,
    default: "text",
    values: ~w(text email password tel url search time datetime-local month week)

  attr :debounce, :any,
    default: nil,
    doc: "the phx-debounce value; derived from the field unless set (see validation_delayed?)"

  attr :rest, :global, include: ~w(autocomplete disabled form list maxlength minlength pattern placeholder
                readonly required size step)

  @spec text(map()) :: Rendered.t()
  def text(%{field: field} = assigns) when not is_nil(field) do
    assigns |> Inputs.prepare() |> text()
  end

  def text(assigns) do
    ~H"""
    <Inputs.field label={@label} errors={@errors} description={@description}>
      <input
        type={@type}
        id={@id}
        name={@name}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        phx-debounce={@debounce}
        class={[@class || "input w-full", @errors != [] && (@error_class || "input-error")]}
        {@rest}
      />
    </Inputs.field>
    """
  end
end
