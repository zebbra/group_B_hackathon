defmodule MyAppWeb.Components.Cinder.Controls do
  @moduledoc """
  Custom `:controls` slot for `Cinder.collection`: search on its own line, with
  the filters flowing into the same row on `md+` and moving into a right-side
  slide-in drawer on small screens.

  Filters render once (they live inside Cinder's `phx-change` form). The drawer
  is a client-only `data-open` toggle, shielded by `JS.ignore_attributes` so a
  filter-driven re-render can't strip the open state.

  While the drawer is open the page behind it does not scroll: `filter-drawer.css`
  locks `body` via `:has(.filter-drawer[data-open])`, inside the same
  `width < 48rem` query that makes the panel a drawer at all, so every way of
  closing it — and resizing up to `md` — releases the lock. Tab is kept inside
  the panel by the `.FilterDrawer` hook below.

  ## Examples

      <Cinder.collection resource={MyApp.Accounts.User} ...>
        <:controls :let={controls}>
          <MyAppWeb.Components.Cinder.Controls.filter_controls controls={controls} />
        </:controls>

        ...
      </Cinder.collection>

  """

  use Phoenix.Component

  import MyAppWeb.Components.Core.Button
  import MyAppWeb.Components.Core.Icon

  alias Phoenix.LiveView.ColocatedHook
  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.Rendered

  attr :controls, :map, required: true

  @spec filter_controls(map()) :: Rendered.t()
  def filter_controls(assigns) do
    drawer_id = "#{assigns.controls.table_id}-filter-drawer"
    panel_id = drawer_id <> "-panel"
    overlay_id = drawer_id <> "-overlay"

    open_js =
      %JS{}
      |> JS.set_attribute({"data-open", "true"}, to: "#" <> panel_id)
      |> JS.set_attribute({"data-open", "true"}, to: "#" <> overlay_id)

    close_js =
      %JS{}
      |> JS.remove_attribute("data-open", to: "#" <> panel_id)
      |> JS.remove_attribute("data-open", to: "#" <> overlay_id)

    assigns =
      assigns
      |> assign(:panel_id, panel_id)
      |> assign(:overlay_id, overlay_id)
      |> assign(:open_js, open_js)
      |> assign(:close_js, close_js)
      |> assign(
        :reset_js,
        JS.push("filter_change", value: %{filters: %{}}, target: assigns.controls.target)
      )
      |> assign(:has_filters, assigns.controls.filters != [])

    ~H"""
    <div class="md:flex md:flex-wrap md:items-center md:gap-2">
      <div class="flex items-center gap-2">
        <div class="flex-1 md:flex-none">
          <Cinder.Controls.render_search
            search={@controls.search}
            theme={@controls.theme}
            target={@controls.target}
          />
        </div>

        <div :if={@has_filters} class="indicator md:hidden">
          <span
            :if={@controls.active_filter_count > 0}
            class="indicator-item badge badge-primary badge-sm"
          >
            {@controls.active_filter_count}
          </span>
          <.button shape={:square} phx-click={@open_js} aria-label="Open filters" data-drawer-toggle>
            <.icon name="tabler-filter" class="size-4" />
          </.button>
        </div>
      </div>

      <div
        :if={@has_filters}
        id={@panel_id}
        phx-hook=".FilterDrawer"
        phx-mounted={JS.ignore_attributes(["data-open"])}
        phx-window-keydown={@close_js}
        phx-key="escape"
        class="filter-drawer"
      >
        <div class="flex items-center justify-between md:hidden">
          <h3 class="text-lg font-semibold">Filters</h3>
          <.button
            style={:ghost}
            shape={:square}
            size={:sm}
            phx-click={@close_js}
            aria-label="Close filters"
          >
            <.icon name="tabler-x" class="size-4" />
          </.button>
        </div>

        <Cinder.Controls.render_filter
          :for={{_key, filter} <- @controls.filters}
          filter={filter}
          theme={@controls.theme}
          target={@controls.target}
          filter_values={@controls.filter_values}
          raw_filter_params={@controls.raw_filter_params}
        />

        <.button
          :if={@controls.active_filter_count > 0}
          shape={:square}
          style={:outline}
          phx-click={@reset_js}
          class="md:tooltip md:tooltip-left"
          data-tip="Reset filters"
        >
          <.icon name="tabler-filter-off" class="size-4" />
          <span class="md:hidden">Reset filters</span>
        </.button>
      </div>

      <div
        :if={@has_filters}
        id={@overlay_id}
        phx-click={@close_js}
        phx-mounted={JS.ignore_attributes(["data-open"])}
        aria-hidden="true"
        class="filter-drawer-backdrop"
      />

      <script :type={ColocatedHook} name=".FilterDrawer" extension="ts">
        import { ViewHook } from "phoenix_live_view";

        const FOCUSABLE = [
          "a[href]",
          "button:not([disabled])",
          'input:not([disabled]):not([type="hidden"])',
          "select:not([disabled])",
          "textarea:not([disabled])",
          '[tabindex]:not([tabindex="-1"])',
        ].join(", ");

        export default class extends ViewHook {
          declare observer: MutationObserver;

          mounted() {
            this.el.addEventListener("keydown", (e) => this.onKeydown(e));

            this.observer = new MutationObserver((records) => {
              if (records.some((record) => record.type === "attributes")) this.onToggle();
              else this.recoverFocus();
            });

            this.observer.observe(this.el, {
              attributeFilter: ["data-open"],
              childList: true,
              subtree: true,
            });
          }

          destroyed() {
            this.observer.disconnect();
          }

          onToggle(): void {
            if (!this.drawerMode()) return;

            if (this.el.hasAttribute("data-open")) {
              requestAnimationFrame(() => {
                const [first] = this.focusable();
                if (first) first.focus();
              });
            } else if (this.el.contains(document.activeElement)) {
              const toggle = this.el.parentElement?.querySelector<HTMLElement>("[data-drawer-toggle]");
              if (toggle) toggle.focus({ preventScroll: true });
            }
          }

          recoverFocus(): void {
            if (!this.trapping() || document.activeElement !== document.body) return;

            const [first] = this.focusable();
            if (first) first.focus({ preventScroll: true });
          }

          onKeydown(e: KeyboardEvent): void {
            if (e.key !== "Tab" || !this.trapping()) return;

            const items = this.focusable();
            if (items.length === 0) return;

            const first = items[0];
            const last = items[items.length - 1];

            if (e.shiftKey && document.activeElement === first) {
              e.preventDefault();
              last.focus();
            } else if (!e.shiftKey && document.activeElement === last) {
              e.preventDefault();
              first.focus();
            }
          }

          focusable(): HTMLElement[] {
            return [...this.el.querySelectorAll<HTMLElement>(FOCUSABLE)].filter(
              (el) => el.getClientRects().length > 0 && getComputedStyle(el).visibility !== "hidden",
            );
          }

          drawerMode(): boolean {
            return window.matchMedia("(width < 48rem)").matches;
          }

          trapping(): boolean {
            return this.el.hasAttribute("data-open") && this.drawerMode();
          }
        }
      </script>
    </div>
    """
  end
end
