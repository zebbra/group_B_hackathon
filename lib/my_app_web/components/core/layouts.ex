defmodule MyAppWeb.Components.Core.Layouts do
  @moduledoc """
  This module holds layouts and related functionality used by your application.

  ```heex
  <Layouts.app flash={@flash} current_user={@current_user} socket={@socket}>
    <h1>Content</h1>
  </Layouts.app>
  ```

  The default `root.html.heex` template, embedded below, contains the HTML
  skeleton of your application: HTML headers and other static content.

  ## Supported components

  - App (the default app shell: header, main content, flash group)
  - Flash group (LiveToast-backed flashes and toasts)
  - Locale switcher
  - Theme toggle

  """

  use MyAppWeb, :html

  alias MyAppWeb.Components.Core.Layouts
  alias Phoenix.LiveView.Rendered

  embed_templates "layouts/*"

  @doc """
  Renders the app layout: header, main content, and the flash group. Typically
  invoked from every LiveView template.
  """
  @spec app(map()) :: Rendered.t()
  defdelegate app(assigns), to: Layouts.App

  @doc """
  Renders flash messages and programmatic toasts (see
  `MyAppWeb.Components.Core.Toast`) through `LiveToast.toast_group/1`, styled
  as daisyUI alerts.
  """
  @spec flash_group(map()) :: Rendered.t()
  defdelegate flash_group(assigns), to: Layouts.FlashGroup

  @doc """
  Renders a locale switcher for all known Gettext locales, each a plain link
  with a `?locale=` query param forcing a full page reload.
  """
  @spec locale_switcher(map()) :: Rendered.t()
  defdelegate locale_switcher(assigns), to: Layouts.LocaleSwitcher

  @doc """
  Renders a system/light/dark theme toggle based on the themes defined in
  `app.css`.
  """
  @spec theme_toggle(map()) :: Rendered.t()
  defdelegate theme_toggle(assigns), to: Layouts.ThemeToggle
end
