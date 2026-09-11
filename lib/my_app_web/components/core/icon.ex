defmodule MyAppWeb.Components.Core.Icon do
  @moduledoc """
  Generic icon component.

  Supports the [Tabler](https://tabler.io/icons) icon library.
  """

  use Phoenix.Component

  alias Phoenix.LiveView.Rendered

  @doc """
  Renders a [Tabler icon](https://tabler.io/icons).

  Tabler icons come in two styles – outline and filled.
  By default, the outline style is used, but the filled style may
  be applied by using the `-filled` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/tabler_icons` directory and bundled within
  your compiled app.css by the plugin in `assets/vendor/tabler.js`.

  ## Examples

      <.icon name="tabler-x" />
      <.icon name="tabler-refresh" class="ml-1 size-3 motion-safe:animate-spin" />

  """
  attr :name, :string, required: true
  attr :class, :any, default: "size-4"
  attr :rest, :global

  @spec icon(map()) :: Rendered.t()
  def icon(%{name: "tabler-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} {@rest} />
    """
  end
end
