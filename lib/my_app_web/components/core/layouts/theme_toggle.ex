defmodule MyAppWeb.Components.Core.Layouts.ThemeToggle do
  @moduledoc false

  use MyAppWeb, :html

  alias Phoenix.LiveView.Rendered

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  @spec theme_toggle(map()) :: Rendered.t()
  def theme_toggle(assigns) do
    ~H"""
    <div class="join">
      <.button
        size={:sm}
        shape={:square}
        data-phx-theme="system"
        class="join-item"
        phx-click={JS.dispatch("phx:set-theme")}
      >
        <.icon name="tabler-device-desktop" class="size-4" />
      </.button>
      <.button
        size={:sm}
        shape={:square}
        data-phx-theme="light"
        class="join-item"
        phx-click={JS.dispatch("phx:set-theme")}
      >
        <.icon name="tabler-sun" class="size-4" />
      </.button>
      <.button
        size={:sm}
        shape={:square}
        data-phx-theme="dark"
        class="join-item"
        phx-click={JS.dispatch("phx:set-theme")}
      >
        <.icon name="tabler-moon" class="size-4" />
      </.button>
    </div>
    """
  end
end
