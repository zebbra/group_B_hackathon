defmodule MyAppWeb.Hooks.LiveParticipant do
  @moduledoc """
  Resolves the session's participant token (set by `MyAppWeb.Plugs.ParticipantSession`) into a
  `MyApp.Positions.Participant` and assigns it as `:current_participant` (`nil` without a token).
  A signed-in user maps to one participant keyed by their user id instead of the cookie.
  """

  import Phoenix.Component, only: [assign: 3]

  alias MyApp.Positions.Participant
  alias Phoenix.LiveView.Socket

  @doc false
  @spec on_mount(atom(), map(), map(), Socket.t()) :: {:cont, Socket.t()}
  def on_mount(:default, _params, session, socket) do
    participant =
      case {socket.assigns[:current_user], session["participant_token"]} do
        {%{id: user_id}, _token} ->
          Participant.ensure!(%{session_token: "user:#{user_id}", user_id: user_id})

        {nil, token} when is_binary(token) ->
          Participant.ensure!(%{session_token: token})

        _ ->
          nil
      end

    {:cont, assign(socket, :current_participant, participant)}
  end
end
