defmodule MyAppWeb.Components.Core.Navigation.SimpleLink do
  @moduledoc false

  use MyAppWeb, :html

  alias Phoenix.LiveView.Rendered

  @doc """
  Renders a navigation link with an active state.

  ## Examples

      <Core.Navigation.simple_link
        navigate={~p"/users"}
        label={~t"Users"}
        active?={@live_action == :users}
      />

  """
  attr :label, :string, required: true
  attr :active?, :boolean, required: true
  attr :class, :any, default: nil, doc: "extra classes appended to the computed ones"

  attr :rest, :global, include: ~w(href navigate patch)

  @spec simple_link(map()) :: Rendered.t()
  def simple_link(assigns) do
    ~H"""
    <.link
      class={["whitespace-nowrap text-sm underline underline-offset-8 transition-all", @active? && "decoration-base-content", not @active? && "decoration-transparent hover:decoration-base-content/40", @class]}
      aria-current={@active? && "page"}
      {@rest}
    >
      {@label}
    </.link>
    """
  end
end
