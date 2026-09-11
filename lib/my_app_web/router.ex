defmodule MyAppWeb.Router do
  @moduledoc """
  The web router.
  """

  use MyAppWeb, :router
  use AshAuthentication.Phoenix.Router

  import AshAuthentication.Plug.Helpers
  import MyAppWeb.Locale, only: [assign_current_locale: 2]
  import Oban.Web.Router
  import Phoenix.LiveDashboard.Router

  alias AshAuthentication.Phoenix.Overrides.Default
  alias Cldr.Plug.PutLocale
  alias Elixir.AshAuthentication.Phoenix.Overrides.DaisyUI
  alias MyApp.Accounts.User
  alias MyAppWeb.Hooks.LiveLocale
  alias MyAppWeb.Plugs.EnsureAdmin

  @default_csp %{
    "content-security-policy" =>
      "default-src 'self'; connect-src 'self' ws: wss:; img-src 'self' data: blob:; script-src 'self'; style-src 'self' 'unsafe-inline'; font-src 'self' data:; frame-ancestors 'self'"
  }

  pipeline :locale do
    plug :fetch_session

    plug PutLocale,
      apps: [:cldr, :gettext],
      from: [:query, :path, :route, :session, :accept_language],
      default: "en",
      gettext: MyAppWeb.Gettext,
      cldr: MyAppWeb.Cldr,
      param: "locale"

    plug :protect_from_forgery
    plug :assign_current_locale

    plug Cldr.Plug.PutSession
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MyAppWeb.Components.Core.Layouts, :root}
    plug :protect_from_forgery

    # default CSP headers
    plug :put_secure_browser_headers, @default_csp

    # custom nonce CSP headers
    plug MyAppWeb.Plugs.CSP

    plug :load_from_session
  end

  pipeline :participant do
    plug MyAppWeb.Plugs.ParticipantSession
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :load_from_bearer
    plug :set_actor, :user
  end

  scope "/", MyAppWeb.Live do
    pipe_through [:locale, :browser, :participant]

    ash_authentication_live_session :authenticated_routes, on_mount: [LiveLocale] do
      # in each liveview, add one of the following at the top of the module:
      #
      # If an authenticated user must be present:
      # on_mount {MyAppWeb.Hooks.LiveUserAuth, :live_user_required}
      #
      # If an authenticated user *may* be present:
      # on_mount {MyAppWeb.Hooks.LiveUserAuth, :live_user_optional}
      #
      # If an authenticated user must *not* be present:
      # on_mount {MyAppWeb.Hooks.LiveUserAuth, :live_no_user}

      live "/", CheckIn
    end
  end

  scope "/", MyAppWeb do
    pipe_through [:locale, :browser]

    auth_routes AuthController, User, path: "/auth"
    sign_out_route AuthController

    sign_in_route register_path: "/register",
                  reset_path: "/reset",
                  auth_routes_prefix: "/auth",
                  gettext_backend: {MyAppWeb.Gettext, "auth"},
                  on_mount: [{MyAppWeb.Hooks.LiveUserAuth, :live_no_user}, LiveLocale],
                  overrides: [MyAppWeb.AuthOverrides, DaisyUI, Default]

    magic_sign_in_route(User, :magic_link,
      auth_routes_prefix: "/auth",
      on_mount: [LiveLocale],
      overrides: [MyAppWeb.AuthOverrides, DaisyUI, Default]
    )
  end

  # Suppress requests of chrome devtools to not have polluted logs
  scope "/.well-known", MyAppWeb do
    pipe_through :api

    get "/appspecific/com.chrome.devtools.json", PageController, :fallback_404
  end

  # LiveDashboard is mounted in every environment, so it stays admin-only.
  scope "/dev" do
    pipe_through [:browser, EnsureAdmin]

    live_dashboard "/dashboard", metrics: MyAppWeb.Telemetry
  end

  # The mailbox preview exists only in local development (`dev_routes` is set in
  # config/dev.exs). There it renders mail the local Swoosh adapter kept in
  # memory on this machine — nothing worth protecting, and requiring a sign-in
  # would mean checking the magic-link mail you cannot read yet.
  if Application.compile_env(:my_app, :dev_routes) do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  scope "/" do
    pipe_through [:locale, :browser, EnsureAdmin]

    oban_dashboard("/oban")
  end
end
