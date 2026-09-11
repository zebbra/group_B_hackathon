defmodule MyAppWeb.Components.Core.Inputs.Radio do
  @moduledoc false

  use MyAppWeb, :html

  alias MyAppWeb.Components.Core.Inputs
  alias Phoenix.LiveView.Rendered

  require Inputs

  @doc """
  Renders a radio group.

  Options are `{label, value}` tuples, as produced by
  `MyApp.Shared.EnumData.options/0`.

  ## Examples

      <Core.Inputs.radio field={@form[:status]} label={~t"Status"} options={Status.options()} />
  """

  Inputs.common_attributes()

  attr :options, :list, required: true, doc: "the options as {label, value} tuples"
  attr :rest, :global, include: ~w(disabled form required)

  @spec radio(map()) :: Rendered.t()
  def radio(%{field: field} = assigns) when not is_nil(field) do
    assigns |> Inputs.prepare() |> radio()
  end

  def radio(assigns) do
    ~H"""
    <div class="fieldset">
      <span :if={@label || @errors != []} class="mb-1 flex items-end justify-between gap-4">
        <span :if={@label} class="label">
          {@label}
        </span>

        <Inputs.errors errors={@errors} />
      </span>

      <div class="flex flex-col gap-1.5">
        <label :for={{label, value} <- @options} class="flex cursor-pointer items-center gap-2">
          <input
            type="radio"
            id={"#{@id}-#{value}"}
            name={@name}
            value={value}
            checked={to_string(value) == to_string(@value)}
            class={@class || "radio radio-sm"}
            {@rest}
          />
          <span class="label">{label}</span>
        </label>
      </div>

      <Inputs.footer description={@description} />
    </div>
    """
  end
end
