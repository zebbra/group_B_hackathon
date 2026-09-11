defmodule MyAppWeb.Live.Start do
  @moduledoc false
  use MyAppWeb, :live_view

  alias MyAppWeb.Components.Core.Layouts
  alias Phoenix.LiveView.Socket

  on_mount {MyAppWeb.Hooks.LiveUserAuth, :live_user_optional}

  @impl Phoenix.LiveView
  @spec mount(Phoenix.LiveView.unsigned_params(), map(), Socket.t()) :: {:ok, Socket.t()}
  def mount(_params, _session, socket) do
    socket
    |> assign(:page_title, ~t"Landing")
    |> ok()
  end

  @impl Phoenix.LiveView
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user} socket={@socket}>
      <h1 class="text-2xl font-semibold tracking-tight">{~t"Landing"}</h1>
    </Layouts.app>
    """
  end
end
