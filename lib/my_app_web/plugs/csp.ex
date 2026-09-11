defmodule MyAppWeb.Plugs.CSP do
  @moduledoc """
  This module provides a plug for setting Content Security Policy (CSP) headers. Request based nonce generation and exceptions for http://127.0.0.1:4007 (local development wss endpoint).
  """

  import Plug.Conn

  @doc false
  @spec init(Plug.opts()) :: Plug.opts()
  def init(opts), do: opts

  @doc false
  @spec call(Plug.Conn.t(), Plug.opts()) :: Plug.Conn.t()
  def call(conn, _opts) do
    nonce = Base.encode64(:crypto.strong_rand_bytes(32))

    # Allow extra hosts from config, e.g. for LiveDebugger in dev
    extra_hosts = :my_app |> Application.get_env(:csp_extra_hosts, []) |> Enum.join(" ")

    csp =
      "default-src 'self'; connect-src 'self' ws: wss: #{extra_hosts}; img-src 'self' data: blob:; script-src 'nonce-#{nonce}' 'self' #{extra_hosts}; style-src 'self' 'unsafe-inline' #{extra_hosts}; font-src 'self' data:; frame-ancestors 'self'"

    conn
    |> assign(:csp_nonce_value, nonce)
    |> put_resp_header("content-security-policy", csp)
  end
end
