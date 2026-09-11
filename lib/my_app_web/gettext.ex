defmodule MyAppWeb.Gettext do
  @moduledoc ~S"""
  The [Gettext](https://hexdocs.pm/gettext) backend holding the app's
  translations, in `priv/gettext`.

  Nothing calls it directly. Translation goes through the `~t` sigil from
  [GettextSigils](https://hexdocs.pm/gettext_sigils), which controllers,
  LiveViews and components inherit from `MyAppWeb`, and which plain modules
  reach with `use MyAppWeb, :translations`:

      ~t"Here is the string to translate"
      ~t"Search #{label}"          # extracts "Search %{label}"
      ~t"Not found"e               # errors domain
      ~t"Here is the string"m      # scoped to the calling module
      ~t"#{count} item(s)"N        # pluralized on the count binding

  See `MyAppWeb.translations/0` for the configured modifiers, and
  `deps/gettext_sigils/usage-rules.md` for the sigil's full behaviour.

  Dependencies that ship their own backend and catalogue (Cinder, for one) are
  left to them; `MyAppWeb.Locale.put_global_locale/0` only passes on the locale
  this backend resolved to, so they translate under it.

  Opaqueness warnings are off for this module. `use Gettext.Backend` generates a
  `<locale>_<domain>_plural/1` function per catalogue that inlines the parsed
  `Plural-Forms:` header with `Macro.escape/1` (gettext `compiler.ex:566`), and
  the escaped literal contains `t:Expo.PluralForms.plural_ast/0`, which expo
  declares opaque. The leak is theirs and none of it is reachable from here.
  """
  use Gettext.Backend, otp_app: :my_app

  @dialyzer :no_opaque
end
