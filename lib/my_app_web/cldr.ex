defmodule MyAppWeb.Cldr do
  @moduledoc """
  Define a backend module that will host our
  Cldr configuration and public API.
  """

  use Cldr,
    otp_app: :my_app,
    gettext: MyAppWeb.Gettext,
    add_fallback_locales: false,
    data_dir: "./priv/cldr",
    providers: [Cldr.Number, Cldr.Calendar, Cldr.DateTime],
    force_locale_download: false
end
