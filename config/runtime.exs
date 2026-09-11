import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/my_app start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :my_app, MyAppWeb.Endpoint, server: true
end

oidc_enabled? = System.get_env("OIDC_ENABLED", "false") in ~w(true 1)

oidc_env = %{
  oidc_client_id: "OIDC_CLIENT_ID",
  oidc_client_secret: "OIDC_CLIENT_SECRET",
  oidc_issuer: "OIDC_ISSUER",
  oidc_redirect_uri: "OIDC_REDIRECT_URI"
}

oidc_values =
  for {key, var} <- oidc_env, value = System.get_env(var), value != "", into: %{} do
    {key, value}
  end

config :my_app, MyAppWeb.Endpoint, http: [port: String.to_integer(System.get_env("PORT", "4000"))]

cond do
  oidc_enabled? and map_size(oidc_values) == map_size(oidc_env) ->
    oidc_trusted_audiences =
      "OIDC_TRUSTED_AUDIENCES"
      |> System.get_env("")
      |> String.split(",")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    config :my_app, Map.to_list(oidc_values)

    if oidc_trusted_audiences != [] do
      config :my_app, oidc_trusted_audiences: oidc_trusted_audiences
    end

  oidc_enabled? ->
    missing =
      for {key, var} <- oidc_env, not Map.has_key?(oidc_values, key), do: var

    raise """
    OIDC_ENABLED is true but OIDC configuration is incomplete. Missing: #{missing |> Enum.sort() |> Enum.join(", ")}.
    Set all OIDC_* variables, or unset OIDC_ENABLED to disable OIDC SSO (requires a rebuild).
    """

  map_size(oidc_values) == 0 ->
    :ok

  true ->
    raise """
    OIDC_* variables are set but OIDC_ENABLED is not true. The :sso strategy is
    only compiled in when OIDC_ENABLED=true at build time; set it consistently
    at build and runtime, or unset the OIDC_* variables.
    """
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  ## Configure the Endpoint
  # Listen IP supports IPv4 and IPv6 addresses.
  {:ok, listen_ip} =
    "LISTEN_IP"
    |> System.get_env("127.0.0.1")
    |> String.to_charlist()
    |> :inet.parse_address()

  port =
    "PORT"
    |> System.get_env("4000")
    |> String.to_integer()

  base_url =
    "BASE_URL"
    |> System.get_env("http://localhost:4000")
    |> URI.parse()

  config :my_app, MyApp.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    # For machines with several cores, consider starting multiple pools of `pool_size`
    # pool_count: 4,
    socket_options: maybe_ipv6

  config :my_app, MyAppWeb.Endpoint,
    url: [scheme: base_url.scheme, host: base_url.host, path: base_url.path, port: base_url.port],
    http: [
      port: port,
      ip: listen_ip
    ],
    secret_key_base: secret_key_base

  config :my_app, :csp_extra_hosts, []
  config :my_app, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :my_app,
    token_signing_secret:
      System.get_env("TOKEN_SIGNING_SECRET") ||
        raise("Missing environment variable `TOKEN_SIGNING_SECRET`!")

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :my_app, MyAppWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :my_app, MyAppWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Here is an example configuration for Mailgun:
  #
  #     config :my_app, MyApp.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # Most non-SMTP adapters require an API client. Swoosh supports Req, Hackney,
  # and Finch out-of-the-box. This configuration is typically done at
  # compile-time in your config/prod.exs:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Req
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
end
