defmodule MyApp.Shared.EnumData do
  @moduledoc ~S"""
  A `use` mechanism for `Ash.Type.Enum` types that carry additional meta
  attributes per enum value (icons, colors, flags, …) next to the labels and
  descriptions Ash supports natively.

  A plain `Ash.Type.Enum` knows its values, labels, and descriptions. In
  practice the UI often needs more: an icon, a badge class, or arbitrary flags
  per value. `EnumData` keeps that data next to the enum definition — one
  module owns the value list *and* everything the rest of the app needs to
  display it, instead of scattering `case` statements across templates.

  Everything except the `:meta` key is passed through to `Ash.Type.Enum`, so
  `label/1`, `description/1`, `details/1`, and `values/0` work as documented
  there.

  ## Defining a type

  ```elixir
  defmodule MyApp.Posts.Types.Status do
    @moduledoc "Enum of valid statuses of a post."

    use MyApp.Shared.EnumData,
      values: [
        draft: [
          label: ~t"Draft",
          meta: [
            icon: "tabler-eye-closed",
            badge_class: "badge-ghost"
          ]
        ],
        published: [
          label: ~t"Published",
          meta: [
            icon: "tabler-eye",
            badge_class: "badge-success"
          ]
        ],
        archived: [
          label: ~t"Archived",
          meta: [
            icon: "tabler-archive",
            badge_class: "badge-neutral"
          ]
        ]
      ]
  end
  ```

  Labels are translated: the `~t` sigil (already `use`d for you through
  `GettextSigils`, backed by `MyAppWeb.Gettext`) extracts the string into the
  POT files at compile time, and the generated `label/1` re-translates it at
  request time in the current locale. The compile-time string doubles as the
  gettext msgid, so it must be the default-locale (English) text. Values without
  a label get the humanized value (`:draft` → `"Draft"`).

  Only plain `~t` and the built-in `N` plural modifier are available here — the
  `m` and `e` modifiers are configured in `MyAppWeb.translations/0`, which the
  domain layer does not use.

  Meta values are compiled into function clauses, not constants — so they are
  evaluated per call. Translations and anonymous functions both work:

  ```elixir
  object: [
    label: ~t"Objects",
    meta: [
      amount: fn count -> ~t"#{count} object(s)"N end,
      icon: "tabler-box"
    ]
  ]
  ```

  ## Using it in an Ash resource

  The module is a regular `Ash.Type.Enum`, so it plugs into an attribute
  directly and validates input as usual:

  ```elixir
  attributes do
    attribute :status, MyApp.Posts.Types.Status do
      allow_nil? false
      default :draft
      public? true
    end
  end
  ```

  ## Displaying values

  `meta/2` accepts the enum value as an atom or a string (handy for URL
  params) and returns one meta entry — `nil` when the key has no entry.
  `meta/1` returns the whole keyword list:

  ```heex
  <span class={["badge gap-1", MyApp.Posts.Types.Status.meta(@post.status, :badge_class)]}>
    <.icon name={MyApp.Posts.Types.Status.meta(@post.status, :icon)} class="size-4" />
    {MyApp.Posts.Types.Status.label(@post.status)}
  </span>
  ```

  ## Select options

  `options/0` returns `{label, value}` tuples in the order of `:values`
  (via `AshPhoenix.AshEnum.options_for_select/1`, using the translated
  labels), ready for the `<.input type="select">` component:

  ```heex
  <.input
    field={@form[:status]}
    type="select"
    label={~t"Status"}
    options={MyApp.Posts.Types.Status.options()}
  />
  ```
  """

  @doc """
  When used, defines an `Ash.Type.Enum` extended with `meta/1`, `meta/2`, and
  `options/0`, plus `label/1`/`description/1` overrides that translate through
  `MyAppWeb.Gettext` at runtime.

  ## Options

  * `:values` - the list of enum values. Required. Each entry is an atom or an
    `{atom, keyword}` pair; the `:meta` key of the keyword list is kept here
    and everything else (`:label`, `:description`) is passed to
    `Ash.Type.Enum`.

  """
  @spec __using__(keyword()) :: Macro.t()
  defmacro __using__(opts) do
    values = Keyword.fetch!(opts, :values)

    if !is_list(values) do
      raise ArgumentError, "`values` must be a literal list, got: #{Macro.to_string(values)}"
    end

    {ash_values, metas} =
      values
      |> Enum.map(fn
        {value, entry} when is_list(entry) ->
          meta = Keyword.get(entry, :meta, [])

          if !is_list(meta) do
            raise ArgumentError,
                  "`meta` for #{inspect(value)} must be a literal keyword list, " <>
                    "got: #{Macro.to_string(meta)}"
          end

          case Keyword.delete(entry, :meta) do
            [] -> {value, {value, meta}}
            rest -> {{value, rest}, {value, meta}}
          end

        {value, description} ->
          {{value, description}, {value, []}}

        value ->
          {value, {value, []}}
      end)
      |> Enum.unzip()

    meta_clauses =
      Enum.map(metas, fn {value, meta} ->
        quote do
          def meta(unquote(value)), do: unquote(meta)
        end
      end)

    quote do
      use MyAppWeb, :translations
      use Ash.Type.Enum, values: unquote(ash_values)

      @impl Ash.Type.Enum
      def label(value) do
        with label when is_binary(label) <- super(value),
             do: Gettext.gettext(MyAppWeb.Gettext, label)
      end

      @impl Ash.Type.Enum
      def description(value) do
        with description when is_binary(description) <- super(value),
             do: Gettext.gettext(MyAppWeb.Gettext, description)
      end

      @doc """
      Returns the meta keyword list for the given enum value.

      Accepts the value as an atom or a string. Raises `ArgumentError` for
      values that are not part of the enum.
      """
      @spec meta(atom() | String.t()) :: keyword()
      def meta(value) when is_binary(value) do
        case match(value) do
          {:ok, matched} -> meta(matched)
          :error -> raise ArgumentError, invalid_value_message(value)
        end
      end

      unquote_splicing(meta_clauses)

      def meta(other) do
        raise ArgumentError, invalid_value_message(other)
      end

      @doc """
      Returns a single meta entry for the given enum value, or `nil` when the
      key has no entry.
      """
      @spec meta(atom() | String.t(), atom()) :: term()
      def meta(value, key), do: value |> meta() |> Keyword.get(key)

      @doc """
      Returns a list of options for use in select inputs.
      ie: `[{"Label 1", :key1}, {"Label 2", :key2}]`
      """
      @spec options() :: list({String.t(), atom()})
      def options, do: AshPhoenix.AshEnum.options_for_select(__MODULE__)

      defp invalid_value_message(value) do
        "expected one of #{inspect(values())}, got: #{inspect(value)}"
      end
    end
  end
end
