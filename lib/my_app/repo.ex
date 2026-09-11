defmodule MyApp.Repo do
  @moduledoc false
  use AshPostgres.Repo,
    otp_app: :my_app

  @doc """
  Defines the extensions to be installed in the database.
  """
  @impl AshPostgres.Repo
  @spec installed_extensions() :: [String.t()]
  def installed_extensions do
    # Add extensions here, and the migration generator will install them.
    ["ash-functions", "citext"]
  end

  @doc """
  Don't open unnecessary transactions
  will default to `false` in 4.0
  """
  @impl AshPostgres.Repo
  @spec prefer_transaction?() :: boolean()
  def prefer_transaction? do
    false
  end

  @doc """
  Defines the minimum PostgreSQL version required for the application.
  """
  @impl AshPostgres.Repo
  @spec min_pg_version() :: Version.t()
  def min_pg_version do
    %Version{major: 17, minor: 7, patch: 0}
  end
end
