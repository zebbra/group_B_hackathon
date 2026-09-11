defmodule MyAppWeb.Plugs.ParticipantSession do
  @moduledoc """
  Mints an opaque participant token into the session on first visit. The token is the
  browser's whole identity: it never leaves the server after the LiveView mounts.
  """
  import Plug.Conn

  @doc false
  @spec init(Plug.opts()) :: Plug.opts()
  def init(opts), do: opts

  @doc false
  @spec call(Plug.Conn.t(), Plug.opts()) :: Plug.Conn.t()
  def call(conn, _opts) do
    if get_session(conn, "participant_token"),
      do: conn,
      else: put_session(conn, "participant_token", Ash.UUID.generate())
  end
end
