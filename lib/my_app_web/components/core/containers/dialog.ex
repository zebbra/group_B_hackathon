defmodule MyAppWeb.Components.Core.Containers.Dialog do
  @moduledoc """
  The open/close plumbing `MyAppWeb.Components.Core.Containers.modal/1` and
  `MyAppWeb.Components.Core.Containers.drawer/1` share.

  Both are a native `<dialog>` driven by the same hook
  (`assets/js/hooks/dialog.ts`), so they answer the same events. Each dialog carries
  a unique DOM id, which is what keeps the two apart on a page holding both.
  Reach for `Modal`'s or `Drawer`'s own delegates rather than this module.
  """

  alias Phoenix.LiveView
  alias Phoenix.LiveView.JS

  @doc "Client-side command to open the dialog with the given id."
  # struct() instead of JS.t() — the type is opaque, naming it here trips dialyzer
  @spec show(String.t()) :: struct()
  def show(dialog_id) do
    JS.dispatch("dialog:open", to: "##{dialog_id}")
  end

  @doc "Client-side command to close the dialog with the given id."
  @spec hide(String.t()) :: struct()
  def hide(dialog_id) do
    JS.dispatch("dialog:close", to: "##{dialog_id}")
  end

  @doc "Opens the dialog with the given id from the server."
  @spec open(LiveView.Socket.t(), String.t()) :: LiveView.Socket.t()
  def open(%LiveView.Socket{} = socket, dialog_id) do
    LiveView.push_event(socket, "open-dialog:#{dialog_id}", %{})
  end

  @doc "Closes the dialog with the given id from the server."
  @spec close(LiveView.Socket.t(), String.t()) :: LiveView.Socket.t()
  def close(%LiveView.Socket{} = socket, dialog_id) do
    LiveView.push_event(socket, "close-dialog:#{dialog_id}", %{})
  end
end
