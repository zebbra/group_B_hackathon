defmodule MyAppWeb.Components.Core.Containers.Drawer do
  @moduledoc false

  use MyAppWeb, :html

  # This module defines its own show/1 and hide/1
  import MyAppWeb.Components.Core.Utils, except: [show: 1, hide: 1], warn: false

  alias MyAppWeb.Components.Core.Containers.Dialog
  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.Rendered
  alias Phoenix.LiveView.Socket

  @doc """
  Renders a side drawer: `MyAppWeb.Components.Core.Containers.modal/1` in a
  full-height panel pinned to one edge of the screen.

  Positioning and animation come from daisyUI's
  [`modal-start`/`modal-end`](https://daisyui.com/components/modal/); `side`
  picks which, and both follow the writing direction, so `:end` is the right
  edge in LTR and the left in RTL.

  `modal={false}` opens it with `show()` rather than `showModal()`: the panel
  slides in over a page that stays live — nothing dimmed, page still scrolling,
  clicks outside it are ordinary clicks. The close button and Escape are then
  the ways out.

  Everything else matches `MyAppWeb.Components.Core.Containers.modal/1`, whose
  docs cover opening, closing and `dismissable`. Rendering it conditionally with
  `open_on_mount` is what a URL-driven drawer wants: `on_cancel` patches the
  query param away, and the drawer unmounts with it.

  A `:header` is wired up as the dialog's accessible name.

  ## Examples

      <.button phx-click={Core.Containers.Drawer.show("details")}>Details</.button>

      <Core.Containers.drawer id="details">
        <:header>{~t"Details"}</:header>
        ...
      </Core.Containers.drawer>

  URL-driven form drawer:

      <.button patch={patch_params(@uri, %{"edit" => @item.id})}>Edit</.button>

      <Core.Containers.drawer :if={@form} id="edit" open_on_mount on_cancel="edit:close">
        <:header>{~t"Edit"}</:header>
        ...
      </Core.Containers.drawer>

  """

  attr :id, :string, required: true
  attr :class, :any, default: nil, doc: "extra classes for the content container"
  attr :size, :atom, default: :md, values: [:sm, :md, :lg]
  attr :side, :atom, default: :end, values: [:start, :end]
  attr :close_button?, :boolean, default: true

  attr :modal, :boolean,
    default: true,
    doc: "set false to keep the page behind the drawer usable — no backdrop, no focus trap"

  attr :open_on_mount, :boolean,
    default: false,
    doc: "open the dialog as soon as it mounts — for conditionally rendered drawers"

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

  @spec drawer(map()) :: Rendered.t()
  def drawer(assigns) do
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
      data-modal={to_string(@modal)}
      closedby={closedby(@modal, @dismissable)}
      aria-labelledby={@header != [] && "#{@id}-title"}
      class={["modal", side_class(@side), not @modal && "[:root:has(&[open])]:[--page-scroll-lock:initial] pointer-events-none bg-transparent"]}
    >
      <div class={["modal-box relative flex h-full w-screen flex-col overflow-hidden p-0", size_class(@size), not @modal && "pointer-events-auto"]}>
        <header
          :if={@header != []}
          id={"#{@id}-title"}
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

      <form :if={@modal and @dismissable} method="dialog" class="modal-backdrop">
        <button>{~t"Close"}</button>
      </form>
    </dialog>
    """
  end

  @doc """
  Client-side command to open the drawer with the given id.
  """
  # struct() instead of JS.t() — the type is opaque, naming it here trips dialyzer
  @spec show(String.t()) :: struct()
  defdelegate show(drawer_id), to: Dialog

  @doc """
  Client-side command to close the drawer with the given id.
  """
  @spec hide(String.t()) :: struct()
  defdelegate hide(drawer_id), to: Dialog

  @doc """
  Opens the drawer with the given id from the server.
  """
  @spec open(Socket.t(), String.t()) :: Socket.t()
  defdelegate open(socket, drawer_id), to: Dialog

  @doc """
  Closes the drawer with the given id from the server.
  """
  @spec close(Socket.t(), String.t()) :: Socket.t()
  defdelegate close(socket, drawer_id), to: Dialog

  # A non-modal dialog gets no close request, and so no Escape, unless it asks.
  @spec closedby(boolean(), boolean()) :: String.t() | nil
  defp closedby(_modal, false), do: "none"
  defp closedby(false, true), do: "closerequest"
  defp closedby(true, true), do: nil

  @spec side_class(atom()) :: String.t()
  defp side_class(:start), do: "modal-start"
  defp side_class(:end), do: "modal-end"

  @spec size_class(atom()) :: String.t()
  defp size_class(:sm), do: "max-w-sm"
  defp size_class(:md), do: "max-w-md"
  defp size_class(:lg), do: "max-w-lg"
end
