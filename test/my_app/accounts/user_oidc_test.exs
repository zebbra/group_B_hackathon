defmodule MyApp.Accounts.UserOidcTest do
  use MyApp.DataCase, async: true

  import MyApp.AccountsFixtures

  test "register_with_sso sets email and roles from the Zitadel roles claim" do
    user =
      user_fixture(%{
        user_info: %{
          "email" => "user@example.com",
          "urn:zitadel:iam:org:project:roles" => %{"admin" => %{}, "member" => %{}}
        }
      })

    assert to_string(user.email) == "user@example.com"
    assert Enum.sort(user.roles) == ["admin", "member"]
  end

  test "register_with_sso sets roles from the standard roles list claim" do
    user =
      user_fixture(%{
        user_info: %{
          "email" => "user-entra@example.com",
          "roles" => ["admin", "member"]
        }
      })

    assert to_string(user.email) == "user-entra@example.com"
    assert Enum.sort(user.roles) == ["admin", "member"]
  end

  test "register_with_sso without roles claim defaults roles to []" do
    user =
      user_fixture(%{
        user_info: %{
          "email" => "user2@example.com"
        }
      })

    assert to_string(user.email) == "user2@example.com"
    assert user.roles == []
  end

  test "register_with_sso sets full_name from user_info" do
    user = user_fixture()

    assert user.full_name == "Frank Grimes"
  end
end
