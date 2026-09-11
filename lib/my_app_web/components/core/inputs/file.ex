defmodule MyAppWeb.Components.Core.Inputs.File do
  @moduledoc false

  use MyAppWeb, :html

  alias MyAppWeb.Components.Core.Inputs
  alias Phoenix.LiveView.Rendered

  require Inputs

  @doc """
  Renders a file input.

  For live file uploads, use `Phoenix.Component.live_file_input/1` instead.

  ## Examples

      <Core.Inputs.file field={@form[:avatar]} label={~t"Avatar"} accept="image/*" />

  """

  Inputs.common_attributes()

  attr :rest, :global, include: ~w(accept capture disabled form multiple required)

  @spec file(map()) :: Rendered.t()
  def file(%{field: field} = assigns) when not is_nil(field) do
    assigns |> Inputs.prepare() |> file()
  end

  def file(assigns) do
    ~H"""
    <Inputs.field label={@label} errors={@errors} description={@description}>
      <input
        type="file"
        id={@id}
        name={@name}
        class={[@class || "file-input w-full", @errors != [] && (@error_class || "file-input-error")]}
        {@rest}
      />
    </Inputs.field>
    """
  end
end
