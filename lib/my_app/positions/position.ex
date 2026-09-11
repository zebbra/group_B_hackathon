defmodule MyApp.Positions.Position do
  @moduledoc """
  A named place a participant can check into. The set is fixed and seeded.
  """
  use Ash.Resource,
    otp_app: :my_app,
    domain: MyApp.Positions,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "positions"
    repo MyApp.Repo
  end

  code_interface do
    define :board, action: :board
    define :seed, action: :seed
  end

  actions do
    defaults [:read]

    read :board do
      prepare build(sort: [sort_order: :asc, name: :asc], load: [:occupant_count])
    end

    create :seed do
      accept [:name, :sort_order]
      upsert? true
      upsert_identity :unique_name
      upsert_fields [:sort_order]
    end
  end

  policies do
    policy action_type(:read) do
      authorize_if always()
    end

    policy action(:seed) do
      authorize_if always()
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: false, public?: true
    attribute :sort_order, :integer, allow_nil?: false, default: 0, public?: true

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    has_many :check_ins, MyApp.Positions.CheckIn
  end

  aggregates do
    count :occupant_count, :check_ins do
      filter expr(is_nil(checked_out_at))
    end
  end

  identities do
    identity :unique_name, [:name]
  end
end
