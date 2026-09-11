defmodule MyAppWeb.Helpers do
  @moduledoc """
  Collection of helper functions for LiveViews and components.

  Automatically imported in LiveViews, LiveComponents, and HTML modules via
  `use MyAppWeb, :live_view` and friends (see the `html_helpers` block in
  `MyAppWeb`).
  """

  alias Phoenix.Component
  alias Phoenix.LiveView.Socket
  alias Plug.Conn.Query

  @doc """
  Wraps a socket in an `{:ok, socket}` tuple, for use at the end of a pipeline.
  """
  @spec ok(Socket.t()) :: {:ok, Socket.t()}
  def ok(socket), do: {:ok, socket}

  @doc """
  Wraps a socket in a `{:noreply, socket}` tuple, for use at the end of a
  pipeline.
  """
  @spec noreply(Socket.t()) :: {:noreply, Socket.t()}
  def noreply(socket), do: {:noreply, socket}

  @doc """
  Assigns the given assigns to the socket and wraps it in a `{:noreply, socket}`
  tuple.
  """
  @spec assign_noreply(Socket.t(), map() | Keyword.t()) :: {:noreply, Socket.t()}
  def assign_noreply(socket, assigns) do
    socket
    |> Component.assign(assigns)
    |> noreply()
  end

  @doc """
  Merges the given query params into the query string of the given URI,
  optionally dropping some keys, and returns the resulting path.

  Useful to build `patch` targets that preserve the current query string.
  """
  @spec patch_params(String.t(), map() | Keyword.t()) :: String.t()
  @spec patch_params(String.t(), map() | Keyword.t(), list()) :: String.t()
  def patch_params(uri, query_params, drop_keys \\ [])

  def patch_params(uri, query_params, drop_keys) when is_list(query_params) do
    query_params = Map.new(query_params, fn {k, v} -> {Atom.to_string(k), v} end)
    patch_params(uri, query_params, drop_keys)
  end

  def patch_params(uri, query_params, drop_keys) do
    %{path: path, query: query} = URI.parse(uri)

    new_query_params =
      (query || "")
      |> Query.decode()
      |> Map.drop(drop_keys)
      |> Map.merge(query_params)
      |> Query.encode()

    String.replace_suffix("#{path}?#{new_query_params}", "?", "")
  end

  @doc """
  Checks whether the query string of the given URI contains the given key.
  """
  @spec params_has_key?(String.t(), String.t()) :: boolean()
  def params_has_key?(uri, key) do
    %{query: query} = URI.parse(uri)

    (query || "")
    |> Query.decode()
    |> Map.has_key?(key)
  end

  @doc """
  Runs a calculation on an already-loaded resource, reusing values already in
  memory instead of hitting the data layer.
  """
  @spec calc(struct(), atom()) :: any()
  def calc(resource, calculation) do
    Ash.calculate!(resource, calculation, reuse_values?: true, data_layer?: false)
  end
end
