defmodule MyAppWeb.Components.Core.Containers.Modal do
  @moduledoc false

  use MyAppWeb, :html

  # This module defines its own show/1 and hide/1
  import MyAppWeb.Components.Core.Utils, except: [show: 1, hide: 1], warn: false

  alias MyAppWeb.Components.Core.Containers.Dialog
  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.Rendered
  alias Phoenix.LiveView.Socket

  @doc """
  Renders a modal on top of daisyUI's [`modal`](https://daisyui.com/components/modal/).

  A native `<dialog>` opened with `showModal()`, so the browser handles the top
  layer, Escape, focus containment and background inertness.

  Open and close it from the client with `show/1` and `hide/1`, or from the
  server with `open/2` and `close/2`.

  Alternatively render it conditionally — `:if={@some_form}` — with
  `open_on_mount` and give `on_cancel` the event that clears that assign; every
  way of dismissing it pushes that event.

  Escape closes an open dropdown inside the dialog before it closes the dialog.
  `dismissable={false}` takes Escape and the backdrop away entirely, so a
  half-filled form cannot be discarded by accident.

  ## Examples

      <.button phx-click={Core.Containers.Modal.show("confirm-modal")}>Delete</.button>

      <Core.Containers.modal id="confirm-modal">
        <:header>{~t"Are you sure?"}</:header>
        <p>{~t"This cannot be undone."}</p>
        <:footer>
          <.button phx-click={Core.Containers.Modal.hide("confirm-modal")}>Cancel</.button>
          <.button color={:error} phx-click="delete">Delete</.button>
        </:footer>
      </Core.Containers.modal>

  Server-driven form dialog:

      <Core.Containers.modal
        :if={@role_form}
        id="role-modal"
        open_on_mount
        on_cancel="role:cancel"
        dismissable={false}
      >
        <:header>{~t"Add role"}</:header>
        ...
      </Core.Containers.modal>

  """

  attr :id, :string, required: true
  attr :class, :any, default: nil, doc: "extra classes for the content container"
  attr :size, :atom, default: :md, values: [:sm, :md, :lg]
  attr :close_button?, :boolean, default: true

  attr :open_on_mount, :boolean,
    default: false,
    doc: "open the dialog as soon as it mounts — for conditionally rendered modals"

  attr :on_cancel, :string,
    default: nil,
    doc: "event pushed when the dialog closes, however it was dismissed"

  attr :on_cancel_target, :any,
    default: nil,
    doc: "`phx-target` for `on_cancel` — `@myself` from a LiveComponent, or a selector"

  attr :dismissable, :boolean,
    default: true,
    doc: "set false to keep Escape and the backdrop from closing the dialog at all"

  attr :exit_duration, :integer,
    default: 300,
    doc: "ms a conditionally rendered dialog is held in the DOM so its panel can animate out — match the panel's CSS"

  slot :inner_block, required: true
  slot :header
  slot :footer

  @spec modal(map()) :: Rendered.t()
  def modal(assigns) do
    ~H"""
    <dialog
      id={@id}
      phx-hook="Dialog"
      phx-mounted={JS.ignore_attributes(["open"])}
      phx-remove={JS.transition("modal-leaving", time: @exit_duration)}
      data-open-on-mount={to_string(@open_on_mount)}
      data-cancel={@on_cancel}
      data-cancel-target={@on_cancel_target && to_string(@on_cancel_target)}
      data-dismissable={to_string(@dismissable)}
      closedby={not @dismissable && "none"}
      aria-labelledby={@header != [] && "#{@id}-title"}
      class="modal"
    >
      <div class={["modal-box max-h-[85dvh] flex flex-col p-0", size_class(@size)]}>
        <header
          :if={@header != []}
          class="border-base-200 flex flex-none items-center justify-between border-b p-4"
        >
          {render_slot(@header)}
        </header>

        <.button
          :if={@close_button?}
          style={:ghost}
          shape={:circle}
          size={:sm}
          class="absolute top-2 right-2"
          phx-click={hide(@id)}
          aria-label={~t"Close"}
        >
          <.icon name="tabler-x" class="size-5" />
        </.button>

        <div class={["grow overflow-auto overscroll-contain p-4", @class]}>
          {render_slot(@inner_block)}
        </div>

        <footer
          :if={@footer != []}
          class="border-base-200 flex flex-none flex-wrap justify-end gap-2 border-t p-4"
        >
          {render_slot(@footer)}
        </footer>
      </div>

      <form :if={@dismissable} method="dialog" class="modal-backdrop">
        <button>{~t"Close"}</button>
      </form>
    </dialog>
    """
  end

  @doc """
  Client-side command to open the modal with the given id.
  """
  # struct() instead of JS.t() — the type is opaque, naming it here trips dialyzer
  @spec show(String.t()) :: struct()
  defdelegate show(modal_id), to: Dialog

  @doc """
  Client-side command to close the modal with the given id.
  """
  @spec hide(String.t()) :: struct()
  defdelegate hide(modal_id), to: Dialog

  @doc """
  Opens the modal with the given id from the server.
  """
  @spec open(Socket.t(), String.t()) :: Socket.t()
  defdelegate open(socket, modal_id), to: Dialog

  @doc """
  Closes the modal with the given id from the server.
  """
  @spec close(Socket.t(), String.t()) :: Socket.t()
  defdelegate close(socket, modal_id), to: Dialog

  @spec size_class(atom()) :: String.t()
  defp size_class(:sm), do: "max-w-sm"
  defp size_class(:md), do: "max-w-lg"
  defp size_class(:lg), do: "max-w-2xl"
end
