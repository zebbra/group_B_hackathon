defmodule MyAppWeb.Components.Core.Layouts.FlashGroup do
  @moduledoc false

  use MyAppWeb, :html

  alias MyAppWeb.Components.Core.Toast
  alias Phoenix.LiveView.Rendered

  @doc """
  Shows the flash and toast group.

  Renders flash messages and programmatic toasts (see
  `MyAppWeb.Components.Core.Toast`) through `LiveToast.toast_group/1`, styled
  as daisyUI alerts. Connection errors (client/server) are handled by
  LiveToast's connection notifications.

  ## Examples

      <.flash_group flash={@flash} socket={@socket} />

  """

  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :id, :string,
    default: "toast-group",
    doc: "the id of the toast container — LiveToast's JS and send_toast/3 target \"toast-group\""

  attr :socket, :any, default: nil, doc: "the LiveView socket, enables live toasts"
  attr :toasts_sync, :list, default: nil, doc: "toasts synchronized via LiveToast.put_toast/3"

  @spec flash_group(map()) :: Rendered.t()
  def flash_group(assigns) do
    ~H"""
    <LiveToast.toast_group
      id={@id}
      flash={@flash}
      connected={not is_nil(@socket)}
      toasts_sync={@toasts_sync}
      kinds={[:info, :success, :warning, :error]}
      corner={:top_right}
      toast_class_fn={&Toast.toast_class_fn/1}
    />
    """
  end
end
