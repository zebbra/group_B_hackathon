defmodule MyApp.PositionsFixtures do
  @moduledoc """
  Factories for positions, participants and check-ins, via real Ash actions.
  """

  alias MyApp.Positions.CheckIn
  alias MyApp.Positions.Participant
  alias MyApp.Positions.Position

  def position_fixture(attrs \\ %{}) do
    Position.seed!(
      Map.merge(%{name: "Position #{System.unique_integer([:positive])}", sort_order: 0}, attrs),
      authorize?: false
    )
  end

  def participant_fixture(attrs \\ %{}) do
    Participant.ensure!(Map.merge(%{session_token: Ash.UUID.generate()}, attrs),
      authorize?: false
    )
  end

  def check_in_fixture(participant, position) do
    CheckIn.check_in!(%{participant_id: participant.id, position_id: position.id},
      authorize?: false
    )
  end
end
