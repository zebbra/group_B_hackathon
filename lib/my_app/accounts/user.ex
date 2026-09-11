defmodule MyApp.Accounts.User do
  @moduledoc """
  User resource and ash actor.
  """
  use Ash.Resource,
    otp_app: :my_app,
    domain: MyApp.Accounts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshAuthentication]

  alias MyApp.Accounts.UserIdentity

  authentication do
    add_ons do
      log_out_everywhere do
        apply_on_password_change? true
      end
    end

    tokens do
      enabled? true
      token_resource MyApp.Accounts.Token
      signing_secret MyApp.Secrets
      store_all_tokens? true
      require_token_presence_for_authentication? true
    end

    strategies do
      magic_link do
        identity_field :email
        registration_enabled? true
        require_interaction? true

        sender MyApp.Accounts.User.Senders.SendMagicLinkEmail
      end

      if Application.compile_env(:my_app, :oidc_enabled) do
        oidc :sso do
          client_id MyApp.Secrets
          client_secret MyApp.Secrets
          base_url MyApp.Secrets
          redirect_uri MyApp.Secrets
          trusted_audiences MyApp.Secrets
          identity_resource UserIdentity
          authorization_params scope: "openid profile email"
          registration_enabled? true
          trust_email_verified? true
        end
      end

      password :password do
        identity_field :email

        # Registration stays magic-link only; password users come from seeds (`:seed_with_password`).
        registration_enabled? false
      end

      remember_me :remember_me
    end
  end

  postgres do
    table "users"
    repo MyApp.Repo
  end

  actions do
    defaults [:read]

    read :get_by_subject do
      description "Get a user by the subject claim in a JWT"
      argument :subject, :string, allow_nil?: false
      get? true
      prepare AshAuthentication.Preparations.FilterBySubject
    end

    read :get_by_email do
      description "Looks up a user by their email"
      get_by :email
    end

    create :sign_in_with_magic_link do
      description "Sign in or register a user with magic link."

      argument :token, :string do
        description "The token from the magic link that was sent to the user"
        allow_nil? false
      end

      argument :remember_me, :boolean do
        description "Whether to generate a remember me token"
        allow_nil? true
      end

      upsert? true
      upsert_identity :unique_email
      upsert_fields [:email]

      # Uses the information from the token to create or sign in the user
      change AshAuthentication.Strategy.MagicLink.SignInChange

      change {AshAuthentication.Strategy.RememberMe.MaybeGenerateTokenChange, strategy_name: :remember_me}

      metadata :token, :string do
        allow_nil? false
      end
    end

    action :request_magic_link do
      argument :email, :ci_string do
        allow_nil? false
      end

      run AshAuthentication.Strategy.MagicLink.Request
    end

    create :seed_with_password do
      description "Creates a user with a password. Used by seeds only."
      accept [:email, :given_name, :family_name]
      argument :password, :string, allow_nil?: false, sensitive?: true
      upsert? true
      upsert_identity :unique_email
      upsert_fields [:given_name, :family_name]
      change {AshAuthentication.Strategy.Password.HashPasswordChange, strategy_name: :password}
    end

    create :register_with_sso do
      argument :user_info, :map, allow_nil?: false
      argument :oauth_tokens, :map, allow_nil?: false
      upsert? true
      upsert_identity :unique_email
      upsert_fields [:email, :roles]

      change fn changeset, _ ->
        user_info = Ash.Changeset.get_argument(changeset, :user_info)

        changeset
        |> set_attr(user_info, :roles)
        |> set_attr(user_info, :email)
        |> set_attr(user_info, :given_name)
        |> set_attr(user_info, :family_name)
      end

      change load :full_name

      change AshAuthentication.Strategy.OAuth2.IdentityChange
      change AshAuthentication.GenerateTokenChange
    end
  end

  policies do
    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if always()
    end
  end

  preparations do
    prepare build(load: [:full_name])
  end

  attributes do
    uuid_primary_key :id

    attribute :email, :ci_string do
      allow_nil? false
      public? true
    end

    attribute :hashed_password, :string do
      sensitive? true
    end

    attribute :given_name, :string do
      public? true
    end

    attribute :family_name, :string do
      public? true
    end

    attribute :roles, {:array, :string} do
      default []
      public? true
      constraints remove_nil_items?: true
    end

    attribute :zip_code, :integer do
      public? true
    end

    attribute :city, :string do
      public? true
    end

    attribute :street, :string do
      public? true
    end

    attribute :phone, :string do
      public? true
    end

    attribute :language, :string do
      public? true
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    has_many :identities, UserIdentity
  end

  calculations do
    calculate :full_name, :string, expr(given_name <> " " <> family_name)
  end

  identities do
    identity :unique_email, [:email]
  end

  defp set_attr(changeset, user_info, :email) do
    email = get_in(user_info, ["email"])

    if email == nil do
      changeset
    else
      Ash.Changeset.change_attribute(changeset, :email, email)
    end
  end

  # Zitadel delivers roles as a map keyed by role name under a URN claim;
  # most other IdPs (e.g. Microsoft Entra ID app roles) use a plain "roles" list.
  defp set_attr(changeset, user_info, :roles) do
    case user_info do
      %{"urn:zitadel:iam:org:project:roles" => roles} when is_map(roles) ->
        Ash.Changeset.change_attribute(changeset, :roles, Map.keys(roles))

      %{"roles" => roles} when is_list(roles) ->
        Ash.Changeset.change_attribute(changeset, :roles, roles)

      _ ->
        changeset
    end
  end

  defp set_attr(changeset, user_info, :given_name) do
    given_name = get_in(user_info, ["given_name"])

    if given_name == nil do
      changeset
    else
      Ash.Changeset.change_attribute(changeset, :given_name, given_name)
    end
  end

  defp set_attr(changeset, user_info, :family_name) do
    family_name = get_in(user_info, ["family_name"])

    if family_name == nil do
      changeset
    else
      Ash.Changeset.change_attribute(changeset, :family_name, family_name)
    end
  end
end
