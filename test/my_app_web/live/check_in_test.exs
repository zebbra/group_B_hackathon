defmodule MyAppWeb.Live.CheckInTest do
  use MyAppWeb.ConnCase

  import MyApp.PositionsFixtures
  import Phoenix.LiveViewTest

  alias AshAuthentication.Plug.Helpers, as: AuthHelpers
  alias MyApp.AccountsFixtures
  alias MyApp.Positions.Participant

  setup do
    %{oak: position_fixture(%{name: "Big Oak", sort_order: 0})}
  end

  defp tile(view, position), do: element(view, ~s|button[phx-value-id="#{position.id}"]|)

  test "a fresh conn mints one participant and a reload reuses it", %{conn: conn} do
    conn = get(conn, "/")
    assert [%Participant{} = participant] = Ash.read!(Participant)

    {:ok, _view, _html} = live(conn, "/")
    assert [%Participant{id: id}] = Ash.read!(Participant)
    assert id == participant.id
  end

  test "clicking a position marks it active with count 1", %{conn: conn, oak: oak} do
    {:ok, view, _html} = live(conn, "/")

    view |> tile(oak) |> render_click()

    assert view |> tile(oak) |> render() =~ "ring-primary"
    assert view |> tile(oak) |> render() =~ "tabler-users-group"
    assert view |> tile(oak) |> render() =~ "</span> 1"
  end

  test "another client sees the new count live", %{conn: conn, oak: oak} do
    {:ok, view_a, _} = live(conn, "/")
    {:ok, view_b, _} = live(build_conn(), "/")

    view_a |> tile(oak) |> render_click()

    assert [_, _] = Ash.read!(Participant)
    assert view_b |> tile(oak) |> render() =~ "</span> 1"
    refute view_b |> tile(oak) |> render() =~ "ring-primary"
  end

  test "tapping another zone moves the participant", %{conn: conn, oak: oak} do
    home = position_fixture(%{name: "Home", sort_order: 5})
    {:ok, view, _html} = live(conn, "/")
    view |> tile(oak) |> render_click()

    view |> tile(home) |> render_click()

    refute view |> tile(oak) |> render() =~ "ring-primary"
    assert view |> tile(home) |> render() =~ "ring-primary"
    assert view |> tile(oak) |> render() =~ "</span> 0"
  end

  test "a signed-in user is the same participant regardless of cookie", %{conn: conn, oak: oak} do
    user = AccountsFixtures.user_fixture()

    conn =
      conn
      |> Phoenix.ConnTest.init_test_session(%{})
      |> AuthHelpers.store_in_session(user)

    {:ok, view, _html} = live(conn, "/")
    view |> tile(oak) |> render_click()

    assert [%Participant{user_id: user_id}] = Ash.read!(Participant)
    assert user_id == user.id
  end
end
