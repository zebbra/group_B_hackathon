defmodule MyAppWeb.Components.Core.Layouts.LocaleSwitcher do
  @moduledoc false

  use MyAppWeb, :html

  alias Phoenix.LiveView.Rendered

  @doc """
  Provides a locale switcher for all known Gettext locales.

  Each locale is a plain link with a `?locale=` query param, forcing a full
  page reload so the new locale applies to all page elements (see
  `MyAppWeb.Hooks.LiveLocale` and the `:locale` router pipeline).
  """

  attr :class, :any, default: nil, doc: "extra classes appended to the computed ones"

  @spec locale_switcher(map()) :: Rendered.t()
  def locale_switcher(assigns) do
    assigns =
      assigns
      |> assign(:current_locale, Gettext.get_locale(MyAppWeb.Gettext))
      |> assign(:locales, Enum.sort(Gettext.known_locales(MyAppWeb.Gettext)))

    ~H"""
    <div class={["join", @class]}>
      <.button
        :for={locale <- @locales}
        size={:sm}
        shape={:square}
        href={"?locale=#{locale}"}
        class={["join-item", locale == @current_locale && "btn-active"]}
      >
        {String.upcase(locale)}
      </.button>
    </div>
    """
  end
end
