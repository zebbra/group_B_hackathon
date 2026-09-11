defmodule MyApp.Positions.ParticipantTest do
  use MyApp.DataCase, async: true

  alias MyApp.Positions.Participant

  test "ensure is idempotent per token and refreshes last_seen_at" do
    token = Ash.UUID.generate()
    first = Participant.ensure!(%{session_token: token})
    second = Participant.ensure!(%{session_token: token})

    assert first.id == second.id
    assert first.display_name == second.display_name
    assert DateTime.after?(second.last_seen_at, first.last_seen_at)
  end

  test "distinct tokens mint distinct participants with display names" do
    a = Participant.ensure!(%{session_token: Ash.UUID.generate()})
    b = Participant.ensure!(%{session_token: Ash.UUID.generate()})

    assert a.id != b.id
    assert a.display_name =~ ~r/^\w+ \w+ \d+$/
  end
end
