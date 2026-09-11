defmodule MyApp.Positions.Participant do
  @moduledoc """
  The anonymous browser identity. One row per session-cookie token.
  """
  use Ash.Resource,
    otp_app: :my_app,
    domain: MyApp.Positions,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "participants"
    repo MyApp.Repo

    references do
      reference :user, on_delete: :delete
    end
  end

  code_interface do
    define :ensure, action: :ensure
  end

  actions do
    defaults [:read]

    read :get_by_session_token do
      get_by :session_token
    end

    create :ensure do
      accept [:session_token, :user_id, :display_name]
      upsert? true
      upsert_identity :unique_session_token
      upsert_fields [:last_seen_at]
      change set_attribute(:last_seen_at, &DateTime.utc_now/0)
      change MyApp.Positions.Changes.GenerateDisplayName
    end
  end

  policies do
    policy always() do
      authorize_if always()
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :session_token, :string, allow_nil?: false, sensitive?: true
    attribute :display_name, :string, allow_nil?: false, public?: true
    attribute :last_seen_at, :utc_datetime_usec

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    has_many :check_ins, MyApp.Positions.CheckIn
    belongs_to :user, MyApp.Accounts.User
  end

  identities do
    identity :unique_session_token, [:session_token]
  end
end
