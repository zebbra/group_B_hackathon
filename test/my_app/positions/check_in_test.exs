defmodule MyApp.Positions.CheckInTest do
  use MyApp.DataCase, async: true

  import MyApp.PositionsFixtures

  alias MyApp.Positions.CheckIn

  setup do
    %{participant: participant_fixture(), oak: position_fixture(), meadow: position_fixture()}
  end

  defp count(position), do: Ash.load!(position, :occupant_count).occupant_count

  test "checking in opens a row and bumps the count", %{participant: p, oak: oak} do
    check_in = check_in_fixture(p, oak)

    assert is_nil(check_in.checked_out_at)
    assert count(oak) == 1
    assert CheckIn.active_for_participant!(p.id).id == check_in.id
  end

  test "switching position closes the first, leaving one open row", %{participant: p} = ctx do
    first = check_in_fixture(p, ctx.oak)
    second = check_in_fixture(p, ctx.meadow)

    assert Ash.get!(CheckIn, first.id).checked_out_at
    assert CheckIn.active_for_participant!(p.id).id == second.id
    assert count(ctx.oak) == 0
    assert count(ctx.meadow) == 1
  end

  test "re-tapping the current position is a no-op", %{participant: p, oak: oak} do
    first = check_in_fixture(p, oak)
    again = check_in_fixture(p, oak)

    assert again.id == first.id
    assert again.checked_in_at == first.checked_in_at
  end

  test "check_out stamps checked_out_at and drops the count", %{participant: p, oak: oak} do
    check_in = check_in_fixture(p, oak)
    closed = CheckIn.check_out!(check_in)

    assert closed.checked_out_at
    assert count(oak) == 0
    assert is_nil(CheckIn.active_for_participant!(p.id))
    assert {:error, _} = CheckIn.check_out(closed)
  end

  test "the partial unique index rejects a second open row", %{
    participant: p,
    oak: oak,
    meadow: m
  } do
    check_in_fixture(p, oak)

    assert {:error, %Ash.Error.Invalid{}} =
             CheckIn.open(%{participant_id: p.id, position_id: m.id})
  end
end
