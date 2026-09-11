defmodule MyApp.Secrets do
  @moduledoc """
  Secrets accessors. Used for authentication and authorization strategies.
  """

  use AshAuthentication.Secret

  alias MyApp.Accounts.User

  @doc """
  Resolves an AshAuthentication secret from application config.

  The path identifies the secret within the resource's `authentication` DSL —
  the token signing secret, or one of the SSO strategy's OIDC settings. Returns
  `:error` when the key is unset, which AshAuthentication treats as the
  strategy being unconfigured.
  """
  @spec secret_for([atom()], Ash.Resource.t(), keyword(), map()) ::
          {:ok, String.t() | [String.t()] | nil} | :error
  def secret_for([:authentication, :tokens, :signing_secret], User, _opts, _context) do
    Application.fetch_env(:my_app, :token_signing_secret)
  end

  def secret_for([:authentication, :strategies, :sso, :client_id], User, _opts, _context) do
    Application.fetch_env(:my_app, :oidc_client_id)
  end

  def secret_for([:authentication, :strategies, :sso, :client_secret], User, _opts, _context) do
    Application.fetch_env(:my_app, :oidc_client_secret)
  end

  def secret_for([:authentication, :strategies, :sso, :site], User, _opts, _context) do
    Application.fetch_env(:my_app, :oidc_issuer)
  end

  def secret_for([:authentication, :strategies, :sso, :base_url], User, _opts, _context) do
    Application.fetch_env(:my_app, :oidc_issuer)
  end

  def secret_for([:authentication, :strategies, :sso, :redirect_uri], User, _opts, _context) do
    Application.fetch_env(:my_app, :oidc_redirect_uri)
  end

  def secret_for([:authentication, :strategies, :sso, :trusted_audiences], User, _opts, _context) do
    {:ok, Application.get_env(:my_app, :oidc_trusted_audiences)}
  end
end
