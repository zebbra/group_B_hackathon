defmodule MyAppWeb.Components.Core.Layouts.App do
  @moduledoc false

  use MyAppWeb, :html

  import MyAppWeb.Components.Core.Layouts.FlashGroup
  import MyAppWeb.Components.Core.Layouts.LocaleSwitcher
  import MyAppWeb.Components.Core.Layouts.ThemeToggle

  alias Phoenix.LiveView.Rendered

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash} current_user={@current_user} socket={@socket}>
        <h1>Content</h1>
      </Layouts.app>

  """

  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :current_user, :map, default: nil, doc: "the current user"
  attr :current_scope, :map, default: nil
  attr :socket, :any, default: nil
  attr :toasts_sync, :list, default: nil, doc: "toasts synchronized via LiveToast.put_toast/3"

  slot :inner_block, required: true

  @spec app(map()) :: Rendered.t()
  def app(assigns) do
    ~H"""
    <header class="navbar px-4 sm:px-6 lg:px-8">
      <div class="flex-1">
        <a href="/" class="flex w-fit flex-1 items-center gap-2">
          <span class="text-xl font-bold">
            MY_APP
          </span>

          <div class="badge badge-accent badge-xs font-semibold">
            {Application.spec(:my_app, :vsn)}
          </div>
        </a>
      </div>

      <div class="flex-none">
        <ul class="flex-column flex items-center space-x-4 px-1">
          <li>
            <.locale_switcher />
          </li>
          <li>
            <.theme_toggle />
          </li>
          <li>
            <.button :if={@current_user} href={~p"/sign-out"} size={:sm}>
              {~t"Sign out"m}
            </.button>
            <.button :if={!@current_user} href={~p"/sign-in"} size={:sm}>
              {~t"Sign in"m}
            </.button>
          </li>
        </ul>
      </div>
    </header>

    <main class="px-4 py-20 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-2xl space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} socket={@socket} toasts_sync={@toasts_sync} />
    """
  end
end
