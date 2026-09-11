defmodule MyAppWeb.Plugs.EnsureAdminTest do
  use MyAppWeb.ConnCase

  import AshAuthentication.Plug.Helpers
  import MyApp.AccountsFixtures

  setup do
    admin = user_fixture(%{roles: ["admin"]})
    user = user_fixture(%{roles: ["backoffice"]})

    %{admin: admin, user: user}
  end

  describe "admin access" do
    test "access granted for admin user on /dev/dashboard/home", %{conn: conn, admin: admin} do
      conn =
        conn
        |> init_test_session(%{})
        |> store_in_session(admin)
        |> get("/dev/dashboard/home")

      assert html_response(conn, 200)
    end
  end

  describe "regular user access" do
    test "access denied for regular user on /dev/dashboard", %{conn: conn, user: user} do
      conn =
        conn
        |> init_test_session(%{})
        |> store_in_session(user)
        |> get("/dev/dashboard")

      assert response(conn, 404)
    end

    test "access denied for regular user on /oban", %{conn: conn, user: user} do
      conn =
        conn
        |> init_test_session(%{})
        |> store_in_session(user)
        |> get("/oban")

      assert response(conn, 404)
    end
  end

  describe "guest access" do
    test "access denied for guest on /dev/dashboard", %{conn: conn} do
      conn = get(conn, "/dev/dashboard")
      assert response(conn, 404)
    end

    test "access denied for guest on /oban", %{conn: conn} do
      conn = get(conn, "/oban")
      assert response(conn, 404)
    end
  end

  describe "mailbox preview" do
    # /dev/mailbox is deliberately unauthenticated, so it must not be mounted
    # outside local development. It is gated on `dev_routes`, which only
    # config/dev.exs sets — these assert the route is absent everywhere else.
    #
    # A 404 is conclusive precisely *because* the route carries no auth plug:
    # were it mounted here, both requests would render the preview with a 200.
    test "is not mounted outside the dev environment", %{conn: conn} do
      conn = get(conn, "/dev/mailbox")

      assert response(conn, 404)
    end

    test "is not mounted outside the dev environment even for an admin", %{
      conn: conn,
      admin: admin
    } do
      conn =
        conn
        |> init_test_session(%{})
        |> store_in_session(admin)
        |> get("/dev/mailbox")

      assert response(conn, 404)
    end
  end
end
