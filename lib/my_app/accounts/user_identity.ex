defmodule MyApp.Accounts.UserIdentity do
  @moduledoc """
  UserIdentity resource is a veriation of the logged in user.
  This is used to have the possibility to log in from different
  auth providers.
  """
  use Ash.Resource,
    otp_app: :my_app,
    domain: MyApp.Accounts,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication.UserIdentity]

  user_identity do
    user_resource MyApp.Accounts.User
  end

  postgres do
    table "user_identities"
    repo MyApp.Repo

    references do
      reference :user, on_delete: :delete
    end
  end
end
