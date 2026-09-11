defmodule MyAppWeb.Hooks.LiveLocale do
  @moduledoc """
  LiveView hook to set the current locale for Cldr/Gettext from the sessions locale,
  which has been set by Cldr.
  """

  import Phoenix.Component, only: [assign: 2]

  alias Cldr.LanguageTag
  alias Phoenix.LiveView.Socket

  require Logger

  @doc """
  Sets the Cldr/Gettext locale for the LiveView process from the session locale
  and assigns it to the socket.
  """
  @spec on_mount(atom(), map(), map(), Socket.t()) :: {:cont, Socket.t()}
  def on_mount(:default, _params, session, socket) do
    locale =
      session
      |> Cldr.Plug.put_locale_from_session()
      |> resolve_locale()

    Logger.debug("LiveLocale set to #{inspect(locale)}")
    MyAppWeb.Locale.put_global_locale()

    {:cont, assign(socket, locale: locale)}
  end

  @spec resolve_locale({:ok, LanguageTag.t()} | {:error, term()}) :: LanguageTag.t()
  defp resolve_locale({:ok, %LanguageTag{} = locale}) do
    if valid_locale?(locale) do
      locale
    else
      Logger.warning(
        "LiveLocale received unknown locale #{locale.cldr_locale_name}, defaulting to #{fallback_locale().cldr_locale_name}"
      )

      fallback_locale()
    end
  end

  @spec resolve_locale({:error, term()}) :: LanguageTag.t()
  defp resolve_locale({:error, reason}) do
    Logger.warning("LiveLocale could not set locale from session: #{inspect(reason)}")
    fallback_locale()
  end

  @spec fallback_locale() :: LanguageTag.t()
  defp fallback_locale do
    MyAppWeb.Cldr.default_locale()
  end

  @spec valid_locale?(LanguageTag.t()) :: boolean()
  defp valid_locale?(%LanguageTag{} = locale) do
    MyAppWeb.Cldr.known_locale_name(locale.cldr_locale_name) != false
  end
end
