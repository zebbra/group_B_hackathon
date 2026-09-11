defmodule MyAppWeb.Components.Core.Badge do
  @moduledoc """
  Generic badge component — a thin wrapper around daisyUI's
  [`badge`](https://daisyui.com/components/badge/).

  ## Examples

      <.badge>Default</.badge>
      <.badge color={:primary}>New</.badge>
      <.badge color={:error} style={:outline} size={:sm}>Failed</.badge>

  """

  use Phoenix.Component

  alias Phoenix.LiveView.Rendered

  attr :color, :atom,
    default: nil,
    values: [nil, :neutral, :primary, :secondary, :accent, :info, :success, :warning, :error]

  attr :style, :atom, default: :solid, values: [:solid, :outline, :soft, :ghost]
  attr :size, :atom, default: :md, values: [:xs, :sm, :md, :lg, :xl]
  attr :class, :any, default: nil, doc: "extra classes appended to the computed ones"
  attr :rest, :global

  slot :inner_block, required: true

  @spec badge(map()) :: Rendered.t()
  def badge(assigns) do
    ~H"""
    <span
      class={["badge", color_class(@color), style_class(@style), size_class(@size), @class]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  @spec color_class(atom() | nil) :: String.t() | nil
  defp color_class(nil), do: nil
  defp color_class(:neutral), do: "badge-neutral"
  defp color_class(:primary), do: "badge-primary"
  defp color_class(:secondary), do: "badge-secondary"
  defp color_class(:accent), do: "badge-accent"
  defp color_class(:info), do: "badge-info"
  defp color_class(:success), do: "badge-success"
  defp color_class(:warning), do: "badge-warning"
  defp color_class(:error), do: "badge-error"

  @spec style_class(atom()) :: String.t() | nil
  defp style_class(:solid), do: nil
  defp style_class(:outline), do: "badge-outline"
  defp style_class(:soft), do: "badge-soft"
  defp style_class(:ghost), do: "badge-ghost"

  @spec size_class(atom()) :: String.t() | nil
  defp size_class(:md), do: nil
  defp size_class(:xs), do: "badge-xs"
  defp size_class(:sm), do: "badge-sm"
  defp size_class(:lg), do: "badge-lg"
  defp size_class(:xl), do: "badge-xl"
end
