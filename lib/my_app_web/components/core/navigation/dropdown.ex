defmodule MyAppWeb.Components.Core.Navigation.Dropdown do
  @moduledoc false

  use MyAppWeb, :html

  alias Phoenix.LiveView.Rendered

  @doc """
  Renders a CSS-only dropdown menu on top of daisyUI's
  [`dropdown`](https://daisyui.com/components/dropdown/), based on
  `<details>`/`<summary>` — no JS needed.

  The `:button` slot is the trigger (styled as a button); the inner block is
  the menu content, typically a list of `<li><.link …></.link></li>`.

  ## Examples

      <Core.Navigation.dropdown id="user-menu">
        <:button><.icon name="tabler-dots-vertical" /></:button>
        <li><.link navigate={~p"/settings"}>{~t"Settings"}</.link></li>
        <li><.link href={~p"/sign-out"}>{~t"Sign out"}</.link></li>
      </Core.Navigation.dropdown>

  """
  attr :id, :string, required: true
  attr :align, :atom, default: :start, values: [:start, :center, :end]
  attr :class, :any, default: nil, doc: "extra classes for the menu container"

  slot :button, required: true do
    attr :class, :any
  end

  slot :inner_block, required: true

  @spec dropdown(map()) :: Rendered.t()
  def dropdown(assigns) do
    ~H"""
    <details id={@id} class={["dropdown", align_class(@align)]}>
      <summary
        :for={button <- @button}
        class={["btn btn-ghost", Map.get(button, :class)]}
        aria-haspopup="menu"
      >
        {render_slot(@button)}
      </summary>
      <ul
        class={["dropdown-content menu bg-base-100 rounded-box border-base-200 z-10 w-52 border p-2 shadow-md", @class]}
        role="menu"
      >
        {render_slot(@inner_block)}
      </ul>
    </details>
    """
  end

  @spec align_class(atom()) :: String.t() | nil
  defp align_class(:start), do: nil
  defp align_class(:center), do: "dropdown-center"
  defp align_class(:end), do: "dropdown-end"
end
