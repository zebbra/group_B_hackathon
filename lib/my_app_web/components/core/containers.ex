defmodule MyAppWeb.Components.Core.Containers do
  @moduledoc """
  This file groups all container and page-structure components.

  ```heex
  <Core.Containers.modal id="confirm-modal">
    <:header>{~t"Are you sure?"}</:header>
    ...
  </Core.Containers.modal>
  ```

  ## Supported components

  - Drawer (URL-driven side panel)
  - Empty state
  - Modal
  - Pagination

  """

  use MyAppWeb, :html

  alias MyAppWeb.Components.Core.Containers
  alias Phoenix.LiveView.Rendered

  @doc """
  Renders a side drawer: a modal in a full-height panel pinned to one edge of
  the screen. Opening and closing work exactly like `modal/1`.
  """
  @spec drawer(map()) :: Rendered.t()
  defdelegate drawer(assigns), to: Containers.Drawer

  @doc """
  Renders a placeholder for empty content (empty lists, no results, …).
  """
  @spec empty_state(map()) :: Rendered.t()
  defdelegate empty_state(assigns), to: Containers.EmptyState

  @doc """
  Renders a modal dialog on top of daisyUI's
  [`modal`](https://daisyui.com/components/modal/), opened with `showModal()`
  so the browser handles focus and Escape.
  """
  @spec modal(map()) :: Rendered.t()
  defdelegate modal(assigns), to: Containers.Modal
end
