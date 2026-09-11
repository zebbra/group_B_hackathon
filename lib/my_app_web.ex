defmodule MyAppWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use MyAppWeb, :controller
      use MyAppWeb, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  @doc false
  @spec static_paths() :: [String.t()]
  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  @doc false
  @spec router() :: Macro.t()
  def router do
    quote do
      use Phoenix.Router, helpers: false

      import Phoenix.Controller
      import Phoenix.LiveView.Router

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
    end
  end

  @doc false
  @spec channel() :: Macro.t()
  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  @doc false
  @spec controller() :: Macro.t()
  def controller do
    quote do
      use Phoenix.Controller, formats: [:html, :json]

      import Plug.Conn

      unquote(translations())

      unquote(verified_routes())
    end
  end

  @doc false
  @spec live_view() :: Macro.t()
  def live_view do
    quote do
      use Phoenix.LiveView

      unquote(html_helpers())
    end
  end

  @doc false
  @spec live_component() :: Macro.t()
  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  @doc false
  @spec html() :: Macro.t()
  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  @doc ~S"""
  The `~t` sigil, for modules that are not controllers or components — plain
  modules reach it with `use MyAppWeb, :translations`.

  `~t"…"` translates, `~t"…"m` scopes the msgid to the calling module, `~t"…"e`
  reads from the `errors` domain, and `~t"…"N` pluralizes on a `count` binding.
  Interpolations become gettext bindings: `~t"Search #{label}"` extracts
  `"Search %{label}"`. The plain Gettext macros stay available alongside it.
  """
  @spec translations() :: Macro.t()
  def translations do
    quote do
      use GettextSigils,
        backend: MyAppWeb.Gettext,
        sigils: [
          modifiers: [
            e: [domain: "errors"],
            m: [context: inspect(__MODULE__)]
          ]
        ]
    end
  end

  @spec html_helpers() :: Macro.t()
  defp html_helpers do
    quote do
      # Auto-imported core UI components
      import MyAppWeb.Components.Core.Badge
      import MyAppWeb.Components.Core.Button
      import MyAppWeb.Components.Core.Icon
      import MyAppWeb.Components.Core.Utils

      # Error handling and general helpers
      import MyAppWeb.Error
      import MyAppWeb.Helpers

      # HTML escaping functionality
      import Phoenix.HTML

      # Common modules used in templates
      alias Phoenix.LiveView.JS

      # Translation
      unquote(translations())

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  @doc false
  @spec verified_routes() :: Macro.t()
  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: MyAppWeb.Endpoint,
        router: MyAppWeb.Router,
        statics: MyAppWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/live_view/etc.
  """
  @spec __using__(atom()) :: Macro.t()
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
