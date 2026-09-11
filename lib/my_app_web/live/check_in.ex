defmodule MyAppWeb.Live.CheckIn do
  @moduledoc """
  The zone board: tap a zone to check in there and see live occupant counts across every
  connected browser. Tapping another zone moves you.
  """
  use MyAppWeb, :live_view

  alias MyApp.Positions.CheckIn
  alias MyApp.Positions.Position
  alias MyAppWeb.Components.Core.Layouts
  alias Phoenix.LiveView.Socket

  on_mount {MyAppWeb.Hooks.LiveUserAuth, :live_user_optional}
  on_mount {MyAppWeb.Hooks.LiveParticipant, :default}

  @topic "check_ins:updated"

  @impl Phoenix.LiveView
  @spec mount(Phoenix.LiveView.unsigned_params(), map(), Socket.t()) :: {:ok, Socket.t()}
  def mount(_params, _session, socket) do
    if connected?(socket), do: MyAppWeb.Endpoint.subscribe(@topic)

    socket
    |> assign(:page_title, ~t"Position check-in")
    |> load_board()
    |> ok()
  end

  @impl Phoenix.LiveView
  @spec handle_event(String.t(), map(), Socket.t()) :: {:noreply, Socket.t()}
  def handle_event("select", %{"id" => id}, %{assigns: %{current_participant: %{id: pid}}} = socket) do
    CheckIn.check_in!(%{participant_id: pid, position_id: id})
    socket |> load_board() |> noreply()
  end

  def handle_event(_event, _params, socket), do: noreply(socket)

  @impl Phoenix.LiveView
  @spec handle_info(term(), Socket.t()) :: {:noreply, Socket.t()}
  def handle_info(%Phoenix.Socket.Broadcast{topic: @topic}, socket) do
    socket |> load_board() |> noreply()
  end

  @spec load_board(Socket.t()) :: Socket.t()
  defp load_board(socket) do
    positions = Position.board!()
    participant = socket.assigns.current_participant

    assign(socket,
      positions: positions,
      max_count: positions |> Enum.map(& &1.occupant_count) |> Enum.max(fn -> 0 end) |> max(1),
      active_check_in: participant && CheckIn.active_for_participant!(participant.id)
    )
  end

  @spec active?(CheckIn.t() | nil, Position.t()) :: boolean()
  defp active?(%CheckIn{position_id: id}, %Position{id: id}), do: true
  defp active?(_active, _position), do: false

  @impl Phoenix.LiveView
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <main class="min-h-dvh flex flex-col gap-3 p-3">
      <p :if={is_nil(@current_participant)} class="text-warning text-sm">
        {~t"Cookies are disabled, so you can watch the board but not check in."}
      </p>

      <div class="grid flex-1 auto-rows-fr grid-cols-2 gap-3">
        <button
          :for={p <- @positions}
          type="button"
          phx-click="select"
          phx-value-id={p.id}
          disabled={is_nil(@current_participant)}
          class={["card rounded-box flex cursor-pointer flex-col justify-between border p-4 text-left transition-colors duration-150 hover:border-primary disabled:cursor-not-allowed", if(active?(@active_check_in, p),
    do: "border-primary bg-primary/10 ring-primary ring-1",
    else: "border-base-300 bg-base-100")]}
        >
          <span class="text-xl font-semibold">{p.name}</span>
          <span class="flex items-center gap-1 text-2xl tabular-nums">
            <.icon
              name={if active?(@active_check_in, p), do: "tabler-users-group", else: "tabler-users"}
              class="size-6"
            /> {p.occupant_count}
          </span>
          <progress class="progress progress-primary h-1.5" value={p.occupant_count} max={@max_count} />
        </button>
      </div>
      <Layouts.flash_group flash={@flash} socket={@socket} />
    </main>
    """
  end
end
