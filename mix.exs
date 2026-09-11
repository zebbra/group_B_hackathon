defmodule MyApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :my_app,
      version: version(),
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      listeners: listeners(),
      consolidate_protocols: Mix.env() != :dev,
      usage_rules: usage_rules(),
      dialyzer: [
        plt_local_path: "priv/plts/project.plt",
        plt_core_path: "priv/plts/core.plt",
        plt_add_apps: [:ex_unit, :mix],
        ignore_warnings: ".dialyzer_ignore.exs",
        list_unused_filters: true
      ],
      name: "MyApp",
      source_url: "https://github.com/your-org/your-app",
      homepage_url: "https://example.com",
      docs: &docs/0
    ]
  end

  defp docs do
    [
      # The main page in the docs
      main: "readme",
      logo: "priv/static/images/logo.svg",
      extras: ["README.md"]
    ]
  end

  defp listeners do
    if System.get_env("DEPENDABOT_HOME"),
      do: [],
      else: [Phoenix.CodeReloader]
  end

  defp usage_rules do
    [
      file: "docs/usage-rules.md",
      usage_rules: [:usage_rules, {~r/.*/, link: :markdown}],
      skills: [
        build: [
          "ash-framework": [
            description:
              "Use this skill when working with Ash Framework or any of its extensions. Always consult this when making domain changes, features, or fixes.",
            usage_rules: [:ash, ~r/^ash_/]
          ],
          "phoenix-framework": [
            description:
              "Use this skill when working with Phoenix Framework. Consult this when working with the web layer, controllers, views, or LiveViews.",
            usage_rules: [:phoenix, :phoenix_live_view, :cinder]
          ]
        ]
      ]
    ]
  end

  defp version do
    System.get_env("APP_VERSION", "0.1.0")
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {MyApp.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  def cli do
    [
      preferred_envs: [
        lint: :test,
        precommit: :test
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      # Phoenix
      {:phoenix, "~> 1.8"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_ecto, "~> 4.0"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.1"},
      {:bandit, "~> 1.5"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},

      # Components
      {:live_toast, "~> 0.8"},
      {:cinder, "~> 0.16"},

      # Ash
      {:ash, "~> 3.0"},
      {:ash_postgres, "~> 2.0"},
      {:ash_phoenix, "~> 2.0"},
      {:ash_authentication, "~> 4.0"},
      {:ash_authentication_phoenix, "~> 2.0"},
      # {:ash_admin, "~> 0.13"},
      # {:ash_ai, "~> 0.4"},
      {:ash_state_machine, "~> 0.2"},
      {:picosat_elixir, "~> 0.2"},

      # Background Jobs
      {:oban, "~> 2.24"},
      {:oban_web, "~> 2.0"},
      {:ash_oban, "~> 0.8"},

      # Emails
      {:swoosh, "~> 1.5"},

      # Internationalization
      {:gettext, "~> 1.0"},
      {:gettext_sigils, "~> 0.5"},
      {:ex_cldr, "~> 2.37"},
      {:ex_cldr_plugs, "~> 1.3"},
      {:ex_cldr_numbers, "~> 2.33"},
      {:ex_cldr_dates_times, "~> 2.19"},
      {:ex_cldr_locale_display, "~> 1.1"},

      # Monitoring
      {:sentry, "~> 13.2"},

      # HTTP client (Swoosh API adapters, OIDC via assent, general use)
      {:req, "~> 0.7"},

      # Assets
      {:bun, "~> 2.0", runtime: Mix.env() in [:dev, :test]},
      {:tabler_icons, github: "tabler/tabler-icons", sparse: "/icons", app: false, compile: false, depth: 1},

      # Dev tools
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_dashboard, "~> 0.9.0"},
      {:doctor, "~> 0.23.0", only: :dev},
      {:ex_doc, "~> 0.39", runtime: false},
      {:mix_test_interactive, "~> 5.1", only: :dev, runtime: false},
      {:tidewave, "~> 0.5", only: [:dev]},
      {:usage_rules, "~> 1.1", only: [:dev]},
      {:live_debugger, "~> 1.0", only: [:dev]},
      {:igniter, "~> 0.6", only: [:dev, :test]},
      {:ecto_dev_logger, "~> 0.15", only: [:dev, :test]},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:tailwind_formatter, "~> 0.4.2", only: [:dev, :test], runtime: false},
      {:styler, "~> 1.10", only: [:dev, :test], runtime: false},
      {:sourceror, "~> 1.8", only: [:dev, :test]},
      {:sobelow, "~> 0.14", only: [:dev, :test], runtime: false},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:floki, ">= 0.30.0", only: :test},
      {:junit_formatter, "~> 3.4", only: :test}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: [
        "deps.get",
        "ash.setup",
        "assets.setup",
        "assets.build",
        "run priv/repo/seeds.exs"
      ],
      reset: [
        "ash_postgres.drop",
        "setup"
      ],
      "ecto.setup": [
        "ecto.create",
        "ecto.migrate",
        "run priv/repo/seeds.exs"
      ],
      "ecto.reset": [
        "ecto.drop",
        "ecto.setup"
      ],
      test: [
        "ash.setup --quiet",
        "test"
      ],

      # Assets
      "assets.setup": [
        "bun.install --if-missing",
        "bun assets install"
      ],
      "assets.lint": [
        "bun assets run lint:eslint",
        "bun assets run lint:prettier",
        "bun assets run lint:tsc",
        # GitHub's dependency graph has no bun.lock parser, so Dependabot
        # alerts never see the JS dependencies.
        "bun assets audit --audit-level=high"
      ],
      "assets.format": [
        "bun assets run format:eslint",
        "bun assets run format:prettier"
      ],
      "assets.build": [
        "compile",
        "bun js",
        "bun css"
      ],
      "assets.deploy": [
        "bun js --production",
        "bun css --minify",
        "phx.digest"
      ],
      lint: [
        # Must run before `compile`: it force-recompiles the whole project, and
        # doing that after protocol consolidation makes every Ash resource warn
        # about its generated `defimpl Inspect`.
        "gettext.extract --check-up-to-date",
        "compile --all-warnings --warnings-as-errors",
        "deps.unlock --check-unused",
        "deps.audit",
        "format --check-formatted",
        "credo --strict",
        "sobelow --config --skip --exit",
        "ash.codegen --check",
        "assets.lint"
        # Makes lint/precommit slow.
        # "dialyzer"
      ],
      precommit: [
        "lint",
        "test"
      ],
      "format.all": [
        "format --force",
        "assets.format"
      ],

      # Docs
      docs: [
        "docs",
        "ash_state_machine.generate_flow_charts",
        "ash.generate_resource_diagrams --format md --type er"
      ]
    ]
  end
end
