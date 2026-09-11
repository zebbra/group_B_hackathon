# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

bun_env = %{
  "NODE_PATH" =>
    Enum.join(
      [
        Path.expand("../assets/node_modules", __DIR__),
        Path.expand("../deps", __DIR__),
        Mix.Project.build_path()
      ],
      ":"
    )
}

config :ash,
  allow_forbidden_field_for_relationships_by_default?: true,
  include_embedded_source_by_default?: false,
  show_keysets_for_all_actions?: false,
  default_page_type: :keyset,
  policies: [no_filter_static_forbidden_reads?: false],
  keep_read_action_loads_when_loading?: false,
  default_actions_require_atomic?: true,
  read_action_after_action_hooks_in_order?: true,
  bulk_actions_default_to_errors?: true,
  transaction_rollback_on_error?: true,
  default_string_length_count: :codepoints,
  known_types: [AshPostgres.Timestamptz, AshPostgres.TimestamptzUsec]

config :ash_oban, pro?: false

config :bun,
  version: "1.4.2",
  assets: [
    args: [],
    cd: Path.expand("../assets", __DIR__),
    env: bun_env
  ],
  js: [
    # --tsconfig-override is required because colocated hooks are extracted to
    # _build, outside the assets directory: bun resolves `paths` (the `@/*`
    # alias) against the tsconfig nearest the importing file, and there is none
    # above _build. NODE_PATH covers the bare `phoenix-colocated/my_app` import.
    #
    # --format=esm pairs with the root layout's <script type="module">: module
    # scope keeps every bundled dependency's top-level bindings off `window`.
    args: ~w(
        build js/app.ts
        --target=browser
        --format=esm
        --outdir=../priv/static/assets/js
        --external /fonts/*
        --external /images/*
        --tsconfig-override
      ) ++ [Path.expand("../assets/tsconfig.json", __DIR__)],
    cd: Path.expand("../assets", __DIR__),
    env: bun_env
  ],
  css: [
    args: ~w(
      x @tailwindcss/cli
      --input=css/app.css
      --output=../priv/static/assets/css/app.css
    ),
    cd: Path.expand("../assets", __DIR__),
    env: bun_env
  ]

config :cinder, :filters, %{
  autocomplete: MyAppWeb.Components.Cinder.Filters.Autocomplete,
  multi_select: MyAppWeb.Components.Cinder.Filters.MultiSelect,
  select: MyAppWeb.Components.Cinder.Filters.Select
}

config :cinder, default_theme: MyAppWeb.Components.Cinder.Theme

# Configure Cldr
config :ex_cldr,
  default_backend: MyAppWeb.Cldr,
  json_library: Jason

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :my_app, MyApp.Mailer, adapter: Swoosh.Adapters.Local
config :my_app, MyAppWeb.Cldr, locales: ["en", "de", "fr"]

# Configure the endpoint
config :my_app, MyAppWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: MyAppWeb.ErrorHTML, json: MyAppWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: MyApp.PubSub,
  live_view: [signing_salt: "04TaRW76"]

config :my_app, Oban,
  engine: Oban.Engines.Basic,
  notifier: Oban.Notifiers.Postgres,
  queues: [default: 10],
  repo: MyApp.Repo,
  lifeline: [rescue_after: {1, :hour}],
  pruner: [max_age: {7, :days}],
  # `AshOban.config/3` injects trigger schedules by matching `Oban.Plugins.Cron`
  # here, and disables the peer when `:plugins` is empty.
  plugins: [{Oban.Plugins.Cron, []}]

config :my_app, :oidc_enabled, System.get_env("OIDC_ENABLED", "false") in ~w(true 1)

config :my_app,
  ecto_repos: [MyApp.Repo],
  generators: [timestamp_type: :utc_datetime],
  ash_domains: [MyApp.Accounts],
  ash_authentication: [return_error_on_invalid_magic_link_token?: true]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :sentry,
  enable_source_code_context: true,
  root_source_code_paths: [File.cwd!()],
  before_send: {MyApp.SentryEventFilter, :filter_event},
  context_lines: 5

config :spark,
  formatter: [
    remove_parens?: true,
    "Ash.Resource": [
      section_order: [
        :admin,
        :authentication,
        :token,
        :user_identity,
        :postgres,
        :resource,
        :code_interface,
        :actions,
        :policies,
        :pub_sub,
        :preparations,
        :changes,
        :validations,
        :multitenancy,
        :attributes,
        :relationships,
        :calculations,
        :aggregates,
        :identities
      ]
    ],
    "Ash.Domain": [
      section_order: [:admin, :resources, :policies, :authorization, :domain, :execution]
    ]
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
