import Config

# Configure your database
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
database_url =
  "ecto://postgres:postgres@localhost:5432/my_app_test#{System.get_env("MIX_TEST_PARTITION")}"

config :ash, policies: [show_policy_breakdowns?: true], disable_async?: true

config :bcrypt_elixir, log_rounds: 1

config :junit_formatter,
  report_file: "test-junit-report.xml",
  report_dir: Path.expand("../test/reports", __DIR__),
  include_filename?: true

# Print only warnings and errors during test
config :logger, level: :warning

# In test we don't send emails
config :my_app, MyApp.Mailer, adapter: Swoosh.Adapters.Test

config :my_app, MyApp.Repo,
  url: System.get_env("DATABASE_URL") || database_url,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :my_app, MyAppWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "R7Ov/FQazMM/1jJCv3cIIb90aLID9DVgDtc30kMF/JNlHgSyFdj2XE/XKfO07F3w",
  server: false

config :my_app, Oban, testing: :inline
config :my_app, :oidc_enabled, true
config :my_app, token_signing_secret: "Su028pz3phXu6qegJFp8baL2sMWohQdD"

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false
