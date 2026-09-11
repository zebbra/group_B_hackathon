defmodule MyAppWeb.Components.Cinder.Filters.Select do
  @moduledoc """
  Renders Cinder's `:select` filter as
  `MyAppWeb.Components.Core.Inputs.select/1`, overriding the built-in type from
  `config/config.exs`.

  Values and querying stay drop-in compatible (`type: :select`, `:equals`), so
  enum columns still need no explicit `options`. The `prompt` is the
  placeholder, the blank option's label and the input's accessible name, and
  `process/2` drops a value the column's options do not offer.
  """

  @behaviour Cinder.Filter

  use MyAppWeb, :html

  alias MyAppWeb.Components.Cinder.Filters.Shared
  alias MyAppWeb.Components.Core.Inputs
  alias Phoenix.LiveView.Rendered

  @blanks ["", "all"]

  @impl Cinder.Filter
  @spec render(map(), any(), map(), map()) :: Rendered.t()
  def render(column, current_value, _theme, assigns) do
    assigns = Shared.base_assigns(column, current_value, assigns)

    ~H"""
    <Inputs.select
      id={@id}
      field={@field}
      value={@value}
      options={@options}
      placeholder={@prompt}
      allow_blank
      blank_label={@prompt}
      class="md:min-w-40"
      aria-label={@prompt}
    />
    """
  end

  @impl Cinder.Filter
  @spec process(any(), map()) :: map() | nil
  def process(raw_value, column) do
    Shared.process_single(raw_value, :select, @blanks, Shared.column_options(column))
  end

  @impl Cinder.Filter
  @spec validate(any()) :: boolean()
  def validate(value), do: Shared.validate_single(value, :select)

  @impl Cinder.Filter
  @spec default_options() :: Keyword.t()
  def default_options, do: [options: [], prompt: nil]

  @impl Cinder.Filter
  @spec empty?(any()) :: boolean()
  def empty?(value), do: Shared.empty_single?(value, @blanks)

  @impl Cinder.Filter
  @spec build_query(term(), term(), map()) :: term()
  def build_query(query, field, %{value: value}), do: Shared.equals_query(query, field, value)
end
