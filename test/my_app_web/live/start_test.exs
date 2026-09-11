defmodule MyAppWeb.Live.StartTest do
  use MyAppWeb.ConnCase

  import Phoenix.LiveViewTest

  test "renders in default locale (en)", %{conn: conn} do
    {:ok, view, html} = live(conn, "/")

    assert html =~ "Sign in"
    assert has_element?(view, ~s|a[href="?locale=en"].btn-active|, "EN")
  end

  test "renders in French when locale param is provided", %{conn: conn} do
    {:ok, view, html} = live(conn, "/?locale=fr")

    assert html =~ "Se connecter"
    assert has_element?(view, ~s|a[href="?locale=fr"].btn-active|, "FR")
  end

  test "renders in German when locale param is provided", %{conn: conn} do
    {:ok, view, html} = live(conn, "/?locale=de")

    assert html =~ "Login"
    assert has_element?(view, ~s|a[href="?locale=de"].btn-active|, "DE")
  end

  test "locale switcher has all known locales", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    assert has_element?(view, ~s|a[href="?locale=de"]|, "DE")
    assert has_element?(view, ~s|a[href="?locale=fr"]|, "FR")
    assert has_element?(view, ~s|a[href="?locale=en"]|, "EN")
  end

  test "persists locale in session after changing it", %{conn: conn} do
    conn = get(conn, "/?locale=fr")
    assert html_response(conn, 200) =~ "Se connecter"

    {:ok, view, html} = live(conn, "/")
    assert html =~ "Se connecter"
    assert has_element?(view, ~s|a[href="?locale=fr"].btn-active|, "FR")
  end
end
