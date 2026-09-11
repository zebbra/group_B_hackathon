defmodule MyAppWeb.Components.Core.Toast do
  @moduledoc """
  Wrapper module around [LiveToast](https://github.com/srcrip/live_toast).

  This module provides a simple API to send toasts from any LiveView:

      Toast.send_icon(:success, ~t"Profile saved.")

  and the daisyUI class functions used by `LiveToast.toast_group/1` in
  `MyAppWeb.Components.Core.Layouts.flash_group/1`. `put_flash/3` keeps working — flashes are
  rendered through the same toast group.
  """

  use MyAppWeb, :html

  alias Phoenix.LiveView.Rendered

  @doc """
  Simple wrapper around `LiveToast.send_toast/3`.

  For options, see https://hexdocs.pm/live_toast/LiveToast.html#t:option/0.
  """
  @spec send(atom(), String.t()) :: Ecto.UUID.t()
  @spec send(atom(), String.t(), Keyword.t()) :: Ecto.UUID.t()
  def send(kind, message, opts \\ []) do
    LiveToast.send_toast(kind, message, opts)
  end

  @doc """
  Sends a toast with a default icon and title for its kind.

  LiveToast only renders the icon as part of the title row, so a per-kind
  title is always set. `opts` are `LiveToast.send_toast/3`'s and override the
  defaults — a stable `:uuid` replaces its own toast rather than stacking
  another, for a message one action can repeat.
  """
  @spec send_icon(atom(), String.t()) :: Ecto.UUID.t()
  @spec send_icon(atom(), String.t(), Keyword.t()) :: Ecto.UUID.t()
  def send_icon(kind, message, opts \\ []) do
    defaults = [
      title: title(kind),
      icon: fn assigns ->
        assigns
        |> Map.put(:name, icon_name(kind))
        |> Map.put(:class, "mr-2 size-5 shrink-0")
        |> toast_icon()
      end
    ]

    LiveToast.send_toast(kind, message, Keyword.merge(defaults, opts))
  end

  @doc """
  Toast class function for `LiveToast.toast_group/1`, styled with daisyUI's
  [`alert`](https://daisyui.com/components/alert/) classes.
  """
  @spec toast_class_fn(map()) :: [String.t() | nil | false]
  def toast_class_fn(assigns) do
    [
      "group/toast pointer-events-auto relative col-start-1 col-end-1 row-start-1 row-end-2",
      "w-full origin-center items-center justify-between overflow-hidden",
      "[@media(scripting:enabled)]:opacity-0 [@media(scripting:enabled)]:in-data-phx-main:opacity-100",
      if(assigns[:rest][:hidden] == true, do: "hidden", else: "flex"),
      "alert text-wrap",
      assigns[:kind] == :info && "alert-info",
      assigns[:kind] == :error && "alert-error",
      assigns[:kind] == :success && "alert-success",
      assigns[:kind] == :warning && "alert-warning"
    ]
  end

  @spec title(atom()) :: String.t()
  defp title(:info), do: ~t"Info"
  defp title(:error), do: ~t"Error"
  defp title(:success), do: ~t"Success"
  defp title(:warning), do: ~t"Warning"
  defp title(kind), do: kind |> Atom.to_string() |> String.capitalize()

  @spec icon_name(atom()) :: String.t()
  defp icon_name(:info), do: "tabler-info-circle"
  defp icon_name(:error), do: "tabler-exclamation-circle"
  defp icon_name(:success), do: "tabler-circle-check"
  defp icon_name(:warning), do: "tabler-alert-triangle"
  defp icon_name(_kind), do: "tabler-hexagon"

  @spec toast_icon(map()) :: Rendered.t()
  defp toast_icon(assigns) do
    ~H"""
    <.icon name={@name} class={@class} />
    """
  end
end
