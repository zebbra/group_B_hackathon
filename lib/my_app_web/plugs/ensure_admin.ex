defmodule MyAppWeb.Plugs.EnsureAdmin do
  @moduledoc """
  Ensures the user has the admin role.
  """
  import Phoenix.Controller
  import Plug.Conn

  @doc false
  @spec init(Plug.opts()) :: Plug.opts()
  def init(opts), do: opts

  @doc false
  @spec call(Plug.Conn.t(), Plug.opts()) :: Plug.Conn.t()
  def call(conn, _opts) do
    user = conn.assigns[:current_user]

    if user && "admin" in (user.roles || []) do
      conn
    else
      conn
      |> put_status(:not_found)
      |> text("Not Found")
      |> halt()
    end
  end
end
