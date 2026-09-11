defmodule MyApp.Accounts do
  @moduledoc false

  use Ash.Domain, otp_app: :my_app

  resources do
    resource MyApp.Accounts.Token
    resource MyApp.Accounts.User
    resource MyApp.Accounts.UserIdentity
  end
end
