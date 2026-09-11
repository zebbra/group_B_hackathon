defmodule MyAppWeb.Components.Core.Inputs.Hidden do
  @moduledoc false

  use MyAppWeb, :html

  alias MyAppWeb.Components.Core.Inputs
  alias Phoenix.LiveView.Rendered

  require Inputs

  @doc """
  Renders a hidden input.

  ## Examples

      <Core.Inputs.hidden field={@form[:token]} />

  """

  Inputs.common_attributes()

  attr :rest, :global, include: ~w(disabled form)

  @spec hidden(map()) :: Rendered.t()
  def hidden(%{field: field} = assigns) when not is_nil(field) do
    assigns |> Inputs.prepare() |> hidden()
  end

  def hidden(assigns) do
    ~H"""
    <input type="hidden" id={@id} name={@name} value={@value} {@rest} />
    """
  end
end
