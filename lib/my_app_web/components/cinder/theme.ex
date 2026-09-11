defmodule MyAppWeb.Components.Cinder.Theme do
  @moduledoc """
  Default [Cinder](https://hexdocs.pm/cinder) theme: daisyUI styling with
  Tabler sort icons, wired as `config :cinder, default_theme:` in
  `config/config.exs`.
  """

  use Cinder.Theme

  extends(:daisy_ui)

  set :container_class, "relative p-0"
  set :controls_class, "p-0"
  set :empty_class, "text-center py-40 text-gray-500"

  set :loading_overlay_class,
      "pointer-events-none absolute inset-0 z-10 flex items-center justify-center"

  set :loading_container_class,
      "flex items-center gap-2 rounded-full border border-base-300 bg-base-100 px-4 py-2 text-sm font-medium shadow-lg"

  set :loading_spinner_class, "loading loading-spinner loading-sm text-primary"

  set :filter_clear_all_class, "hidden"
  set :filter_clear_button_class, "hidden"
  set :filter_container_class, "p-0"
  set :filter_count_class, "hidden"
  set :filter_header_class, nil
  set :filter_input_wrapper_class, nil
  set :filter_inputs_class, "flex flex-col gap-2 md:flex-row md:flex-wrap md:items-center"
  set :filter_label_class, "hidden"
  set :filter_select_input_class, "select w-full md:min-w-40"
  set :filter_title_class, "hidden"

  # Sorting
  set :sort_arrow_wrapper_class, "ml-2"
  set :sort_asc_icon_class, "size-4"
  set :sort_asc_icon_name, "tabler-sort-ascending-2"
  set :sort_buttons_class, "flex gap-1"
  set :sort_desc_icon_class, "size-4"
  set :sort_desc_icon_name, "tabler-sort-descending-2"
  set :sort_icon_class, "ml-1"
  set :sort_indicator_class, nil
  set :sort_none_icon_class, "size-4 opacity-30"
  set :sort_none_icon_name, "tabler-arrows-sort"

  # Table
  set :table_wrapper_class, "mt-4 overflow-x-auto"
  set :table_class, "table table-zebra"

  set :thead_class, nil
  set :th_class, nil
  set :td_class, nil
  set :row_class, nil

  # Pagination
  set :pagination_count_class, "max-sm:hidden text-base-content/50 text-xs ml-2"
end
