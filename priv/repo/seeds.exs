# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Everything here upserts, so re-running is harmless.

alias MyApp.Accounts.User
alias MyApp.Positions.CheckIn
alias MyApp.Positions.Participant
alias MyApp.Positions.Position

zones =
  ["Big Oak", "River Meadow", "Sunny Field", "Rock Hill", "The Green Corner", "Home"]
  |> Enum.with_index()
  |> Enum.map(fn {name, i} -> Position.seed!(%{name: name, sort_order: i}, authorize?: false) end)

# 100 password users (password123), each standing in one of the zones.
for i <- 1..100 do
  email = "user#{i}@example.com"

  user =
    User
    |> Ash.Changeset.for_create(:seed_with_password, %{
      email: email,
      password: "password123",
      given_name: "User",
      family_name: "#{i}"
    })
    |> Ash.create!(authorize?: false)

  participant =
    Participant.ensure!(
      %{
        session_token: "user:#{user.id}",
        user_id: user.id,
        display_name: "#{user.given_name} #{user.family_name}"
      },
      authorize?: false
    )

  CheckIn.check_in!(
    %{participant_id: participant.id, position_id: Enum.at(zones, rem(i, 6)).id},
    authorize?: false
  )
end
