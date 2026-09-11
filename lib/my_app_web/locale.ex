defmodule MyAppWeb.Locale do
  @moduledoc """
  Helper functions to work with locales.
  """

  import Plug.Conn, only: [assign: 3]

  require Logger

  @doc false
  @spec current() :: Cldr.LanguageTag.t()
  def current, do: MyAppWeb.Cldr.get_locale()

  @spec assign_current_locale(Plug.Conn.t(), any) :: Plug.Conn.t()
  def assign_current_locale(conn, _opts \\ []) do
    Logger.debug("Assign locale #{inspect(current())}")
    put_global_locale()

    assign(conn, :locale, current())
  end

  @doc """
  Puts the locale `MyAppWeb.Gettext` resolved to onto Gettext's *global* slot,
  where every other backend in the process picks it up.

  A Gettext locale is per backend, and `Cldr.Plug.PutLocale` only sets the one
  it is handed. A dependency that ships its own backend — Cinder, whose search
  box, pagination and filter prompts are its own strings — would otherwise stay
  in the default locale however the request was negotiated.
  `Gettext.get_locale/1` falls back to the global slot before a backend's
  default, so setting it once covers all of them, including deps added later
  that nobody remembers to wire up.

  The locale is read back off `MyAppWeb.Gettext` rather than taken from CLDR,
  because the two do not always agree: CLDR may negotiate `de-CH` where Gettext
  only has a `de` catalogue, and Gettext has already resolved that.

  Called from `assign_current_locale/2` for requests and from
  `MyAppWeb.Hooks.LiveLocale` for LiveViews. Anything that sets a locale outside
  those — a job, a mailer — should call it too.
  """
  @spec put_global_locale() :: :ok
  def put_global_locale do
    Gettext.put_locale(Gettext.get_locale(MyAppWeb.Gettext))

    :ok
  end
end
