defmodule MyAppWeb.Hooks.LiveUserAuth do
  @moduledoc """
  Helpers for authenticating users in LiveViews.
  """

  use MyAppWeb, :verified_routes

  import Phoenix.Component

  alias AshAuthentication.Phoenix.LiveSession
  alias Phoenix.LiveView.Socket

  @doc """
  This is used for nested liveviews to fetch the current user.
  To use, place the following at the top of that liveview:
  on_mount {MyAppWeb.Hooks.LiveUserAuth, :current_user}
  """
  @spec on_mount(atom(), map(), map(), Socket.t()) :: {:cont | :halt, Socket.t()}
  def on_mount(:current_user, _params, session, socket) do
    {:cont, LiveSession.assign_new_resources(socket, session)}
  end

  @doc false
  def on_mount(:live_user_optional, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:cont, socket}
    else
      {:cont, assign(socket, :current_user, nil)}
    end
  end

  @doc false
  def on_mount(:live_user_required, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:cont, socket}
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/sign-in")}
    end
  end

  @doc false
  def on_mount(:live_no_user, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/")}
    else
      {:cont, assign(socket, :current_user, nil)}
    end
  end
end
