defmodule MyAppWeb.SignInLiveTest do
  use MyAppWeb.ConnCase

  import Phoenix.LiveViewTest

  test "renders magic link form and SSO button", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/sign-in")

    assert html =~ "user[email]"
    assert html =~ "/auth/user/sso"
    assert html =~ "Sign in with SSO"
  end

  test "localizes the SSO button label", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/sign-in?locale=de")

    assert html =~ "Login mit SSO"
  end
end
