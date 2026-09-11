defmodule MyApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  @spec start(Application.start_type(), term()) :: {:ok, pid()} | {:error, term()}
  def start(_type, _args) do
    :logger.add_handler(:sentry_handler, Sentry.LoggerHandler, %{
      config: %{metadata: [:file, :line]}
    })

    # Attach devlogger (for dev env only)
    if System.get_env("MIX_ENV") == "dev" && Code.ensure_loaded?(Ecto.DevLogger) do
      :ok = Ecto.DevLogger.install(MyApp.Repo)
    end

    # Attach default Oban logger
    :ok = Oban.Telemetry.attach_default_logger()

    # Attach Oban reporter
    :ok = MyApp.ObanReporter.attach()

    children = [
      MyAppWeb.Telemetry,
      MyApp.Repo,
      {DNSCluster, query: Application.get_env(:my_app, :dns_cluster_query) || :ignore},
      {Oban,
       AshOban.config(
         Application.fetch_env!(:my_app, :ash_domains),
         Application.fetch_env!(:my_app, Oban)
       )},
      {Phoenix.PubSub, name: MyApp.PubSub},
      # Start a worker by calling: MyApp.Worker.start_link(arg)
      # {MyApp.Worker, arg},
      # Start to serve requests, typically the last entry
      MyAppWeb.Endpoint,
      {AshAuthentication.Supervisor, [otp_app: :my_app]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl Application
  @spec config_change(keyword(), keyword(), [atom()]) :: :ok
  def config_change(changed, _new, removed) do
    MyAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
