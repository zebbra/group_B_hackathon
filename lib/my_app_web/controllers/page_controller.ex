defmodule MyAppWeb.PageController do
  @moduledoc false

  use MyAppWeb, :controller

  require Logger

  @doc """
  Return 404 for requests which we won't handle
  """
  def fallback_404(conn, _params) do
    Logger.debug("Not a request, we want to process")

    send_resp(conn, 404, "")
  end
end
