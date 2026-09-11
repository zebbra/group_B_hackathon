defmodule MyApp.Positions.CheckIn do
  @moduledoc """
  One visit of a participant at a position: an open (`checked_out_at` nil) or closed interval.
  Every create/update broadcasts on `"check_ins:updated"`.
  """
  use Ash.Resource,
    otp_app: :my_app,
    domain: MyApp.Positions,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    notifiers: [Ash.Notifier.PubSub]

  postgres do
    table "check_ins"
    repo MyApp.Repo

    references do
      reference :participant, on_delete: :delete
      reference :position, on_delete: :delete
    end

    custom_indexes do
      index [:participant_id],
        unique: true,
        where: "checked_out_at IS NULL",
        name: "check_ins_one_active_per_participant_index"
    end
  end

  code_interface do
    define :check_in, action: :check_in
    define :open, action: :open
    define :check_out, action: :check_out

    define :active_for_participant,
      action: :active_for_participant,
      args: [:participant_id],
      not_found_error?: false
  end

  actions do
    defaults [:read]

    read :active_for_participant do
      argument :participant_id, :uuid, allow_nil?: false
      get? true
      filter expr(participant_id == ^arg(:participant_id) and is_nil(checked_out_at))
    end

    create :open do
      accept [:participant_id, :position_id]
    end

    action :check_in, :struct do
      constraints instance_of: __MODULE__
      argument :participant_id, :uuid, allow_nil?: false
      argument :position_id, :uuid, allow_nil?: false
      transaction? true

      run fn input, _context ->
        %{participant_id: participant_id, position_id: position_id} = input.arguments

        # Closing the previous visit and opening the new one share a transaction, so the
        # one-active-per-participant index can never be violated.
        case __MODULE__.active_for_participant!(participant_id) do
          %{position_id: ^position_id} = open ->
            {:ok, open}

          open ->
            if open, do: __MODULE__.check_out!(open)
            __MODULE__.open(%{participant_id: participant_id, position_id: position_id})
        end
      end
    end

    update :check_out do
      require_atomic? false
      validate attribute_equals(:checked_out_at, nil), message: "already checked out"
      change set_attribute(:checked_out_at, &DateTime.utc_now/0)
    end
  end

  policies do
    policy always() do
      authorize_if always()
    end
  end

  pub_sub do
    module MyAppWeb.Endpoint
    prefix "check_ins"
    publish_all :create, ["updated"]
    publish_all :update, ["updated"]
  end

  attributes do
    uuid_primary_key :id

    attribute :checked_in_at, :utc_datetime_usec,
      allow_nil?: false,
      default: &DateTime.utc_now/0,
      public?: true

    attribute :checked_out_at, :utc_datetime_usec, public?: true
  end

  relationships do
    belongs_to :participant, MyApp.Positions.Participant, allow_nil?: false
    belongs_to :position, MyApp.Positions.Position, allow_nil?: false
  end
end
