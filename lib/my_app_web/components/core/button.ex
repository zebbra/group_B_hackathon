defmodule MyAppWeb.Components.Core.Button do
  @moduledoc """
  Generic button component — a thin wrapper around daisyUI's
  [`btn`](https://daisyui.com/components/button/).

  Renders a `<button>`, or a `<.link>` when one of `href`, `navigate`, or `patch` is present.

  ## Examples

      <.button phx-click="save">Save</.button>
      <.button color={:primary} size={:lg}>Send!</.button>
      <.button style={:ghost} shape={:square}><.icon name="tabler-x" /></.button>
      <.button navigate={~p"/"} style={:outline}>Home</.button>

  """

  use Phoenix.Component

  alias Phoenix.LiveView.Rendered

  attr :color, :atom,
    default: nil,
    values: [nil, :neutral, :primary, :secondary, :accent, :info, :success, :warning, :error]

  attr :style, :atom, default: :solid, values: [:solid, :outline, :soft, :ghost, :link]
  attr :size, :atom, default: :md, values: [:xs, :sm, :md, :lg, :xl]
  attr :shape, :atom, default: nil, values: [nil, :wide, :block, :square, :circle]
  attr :class, :any, default: nil, doc: "extra classes appended to the computed ones"

  attr :rest, :global, include: ~w(href navigate patch method download name value disabled type form)

  slot :inner_block, required: true

  @spec button(map()) :: Rendered.t()
  def button(%{rest: rest} = assigns) do
    assigns =
      assign(assigns, :btn_class, [
        "btn",
        color_class(assigns.color),
        style_class(assigns.style),
        size_class(assigns.size),
        shape_class(assigns.shape),
        assigns.class
      ])

    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link class={@btn_class} {@rest}>
        {render_slot(@inner_block)}
      </.link>
      """
    else
      ~H"""
      <button class={@btn_class} {@rest}>
        {render_slot(@inner_block)}
      </button>
      """
    end
  end

  @spec color_class(atom() | nil) :: String.t() | nil
  defp color_class(nil), do: nil
  defp color_class(:neutral), do: "btn-neutral"
  defp color_class(:primary), do: "btn-primary"
  defp color_class(:secondary), do: "btn-secondary"
  defp color_class(:accent), do: "btn-accent"
  defp color_class(:info), do: "btn-info"
  defp color_class(:success), do: "btn-success"
  defp color_class(:warning), do: "btn-warning"
  defp color_class(:error), do: "btn-error"

  @spec style_class(atom()) :: String.t() | nil
  defp style_class(:solid), do: nil
  defp style_class(:outline), do: "btn-outline"
  defp style_class(:soft), do: "btn-soft"
  defp style_class(:ghost), do: "btn-ghost"
  defp style_class(:link), do: "btn-link"

  @spec size_class(atom()) :: String.t() | nil
  defp size_class(:md), do: nil
  defp size_class(:xs), do: "btn-xs"
  defp size_class(:sm), do: "btn-sm"
  defp size_class(:lg), do: "btn-lg"
  defp size_class(:xl), do: "btn-xl"

  @spec shape_class(atom() | nil) :: String.t() | nil
  defp shape_class(nil), do: nil
  defp shape_class(:wide), do: "btn-wide"
  defp shape_class(:block), do: "btn-block"
  defp shape_class(:square), do: "btn-square"
  defp shape_class(:circle), do: "btn-circle"
end
