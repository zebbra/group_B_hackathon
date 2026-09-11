defmodule MyAppWeb.Components.Core.Containers.EmptyState do
  @moduledoc false

  use MyAppWeb, :html

  alias Phoenix.LiveView.Rendered

  @doc """
  Renders a placeholder for empty content (empty lists, no results, …).

  ## Examples

      <Core.Containers.empty_state label={~t"No results found."} icon="tabler-search-off" />

  """

  attr :label, :string, required: true
  attr :icon, :string, default: nil
  attr :class, :any, default: nil, doc: "extra classes appended to the computed ones"

  slot :actions, doc: "optional actions (e.g. a create button)"

  @spec empty_state(map()) :: Rendered.t()
  def empty_state(assigns) do
    ~H"""
    <div class={["border-base-300 text-base-content/60 rounded-box flex flex-col items-center justify-center gap-3 border border-dashed p-10 text-center", @class]}>
      <.icon :if={@icon} name={@icon} class="size-8" />
      <p>
        {@label}
      </p>
      <div :if={@actions != []} class="mt-2">
        {render_slot(@actions)}
      </div>
    </div>
    """
  end
end
