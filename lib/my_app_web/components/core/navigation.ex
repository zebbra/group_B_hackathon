defmodule MyAppWeb.Components.Core.Navigation do
  @moduledoc """
  This file groups all navigation related components.

  Each component lives in its own module under `core/navigation/` and is
  re-exported here, so pages only need to `alias MyAppWeb.Components.Core.Navigation`:

  ```heex
  <Navigation.simple_link navigate={~p"/users"} label={~t"Users"} active?={@live_action == :users} />
  ```

  ## Supported components

  - Simple link (nav link with active state)
  - Dropdown (CSS-only menu)

  """

  use MyAppWeb, :html

  alias MyAppWeb.Components.Core.Navigation
  alias Phoenix.LiveView.Rendered

  @doc """
  Renders a navigation link with an active state.
  """
  @spec simple_link(map()) :: Rendered.t()
  defdelegate simple_link(assigns), to: Navigation.SimpleLink

  @doc """
  Renders a CSS-only dropdown menu on top of daisyUI's
  [`dropdown`](https://daisyui.com/components/dropdown/), based on
  `<details>`/`<summary>` — no JS needed.
  """
  @spec dropdown(map()) :: Rendered.t()
  defdelegate dropdown(assigns), to: Navigation.Dropdown
end
