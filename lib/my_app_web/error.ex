defmodule MyAppWeb.Error do
  @moduledoc """
  Convenience functions to surface errors to the user.

  Automatically imported in LiveViews, LiveComponents, and HTML modules via
  `use MyAppWeb, :live_view` and friends (see the `html_helpers` block in
  `MyAppWeb`).
  """

  use MyAppWeb, :translations

  alias MyAppWeb.Components.Core.Toast
  alias Phoenix.LiveView.Socket

  require Logger

  @doc """
  Handles Ash errors as toast notifications.

  Messages from `Ash.Error.Invalid` are localized through the `error` Gettext
  domain, deduped, and batched into a single error toast — several failed
  validations at once (e.g. two required fields) surface as one toast, not
  one per error. Errors without a message — and any non-Ash error — are
  logged and reported with a single generic toast, kept separate from the
  batch so a real validation message is never buried under a generic one.
  """
  @spec handle_error(Socket.t(), any()) :: Socket.t()
  def handle_error(socket, %Ash.Error.Invalid{errors: errors}) do
    {known, unknown} = Enum.split_with(errors, &Map.has_key?(&1, :message))

    if unknown != [], do: log_unhandled(unknown)

    case known do
      [] ->
        if unknown != [], do: send_generic_error()

      known ->
        known |> Enum.map(&localize_error/1) |> Enum.uniq() |> Enum.join(" ") |> send_error()
    end

    socket
  end

  def handle_error(socket, errors) do
    log_unhandled(errors)
    send_generic_error()
    socket
  end

  @spec localize_error(map()) :: String.t()
  defp localize_error(error) do
    raw_vars = Map.get(error, :vars, []) || []
    bindings = if is_map(raw_vars), do: Map.to_list(raw_vars), else: raw_vars

    Gettext.dgettext(MyAppWeb.Gettext, "errors", error.message, bindings)
  end

  @spec log_unhandled(any()) :: :ok
  defp log_unhandled(errors), do: Logger.error("Unhandled errors: #{inspect(errors)}")

  @spec send_error(String.t()) :: String.t()
  defp send_error(message), do: Toast.send_icon(:error, message)

  @spec send_generic_error() :: String.t()
  defp send_generic_error, do: send_error(gettext("An unknown error occurred."))
end
