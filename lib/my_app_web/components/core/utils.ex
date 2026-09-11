defmodule MyAppWeb.Components.Core.Utils do
  @moduledoc """
  Shared UI utilities: JS commands and form error translation.
  """

  alias Phoenix.LiveView.JS

  @doc """
  Shows an element with a transition.
  """
  # struct() instead of JS.t() — the type is opaque, naming it here trips dialyzer
  @spec show(String.t()) :: struct()
  @spec show(struct(), String.t()) :: struct()
  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all ease-out duration-300", "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  @doc """
  Hides an element with a transition.
  """
  @spec hide(String.t()) :: struct()
  @spec hide(struct(), String.t()) :: struct()
  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  @doc """
  Translates an error message using gettext.
  """
  @spec translate_error({String.t(), keyword()}) :: String.t()
  def translate_error({msg, opts}) do
    # Translated strings are normally static, so the `~t` sigil can extract them
    # at compile time:
    #
    #     # Translate the number of files with plural rules
    #     ~t"#{count} file(s)"eN
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so the sigil cannot see them. They go through Gettext's
    # runtime functions instead, with our backend as first argument.
    # Translations are available in the errors.po file (the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(MyAppWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(MyAppWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  @spec translate_errors(keyword(), atom()) :: [String.t()]
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
