defmodule MyApp.AccountsFixtures do
  @moduledoc """
  Factories for creating account-related records in tests.
  """

  alias MyApp.Accounts.User

  @doc """
  Creates and returns a user via the `:register_with_sso` action.

  A Zitadel user_info map looks like this:
  ```elixir
  user_info #=> %{
    "client_id" => "355408558474321614",
    "email" => "example@example.com",
    "email_verified" => true,
    "family_name" => "John",
    "given_name" => "Doe",
    "locale" => nil,
    "name" => "John Doe",
    "preferred_username" => "example@example.com",
    "sid" => "356385832178815321",
    "sub" => "355666530903573943",
    "updated_at" => 1768918509,
    "urn:zitadel:iam:org:project:355407721677213846:roles" => %{
      "admin" => %{"355383107588793827" => "auth.example.com"},
      "bo" => %{"355383107588793827" => "auth.example.com"},
      "coach" => %{"355383107588793827" => "auth.example.com"},
      "case_manager" => %{"355383107588793827" => "auth.example.com"}
    },
    "urn:zitadel:iam:org:project:roles" => %{
      "admin" => %{"355383107588793827" => "auth.example.com"},
      "bo" => %{"355383107588793827" => "auth.example.com"},
      "coach" => %{"355383107588793827" => "auth.zebbra.ch"},
      "case_manager" => %{"355383107588793827" => "auth.zebbra.ch"}
    }
  }
  ```

  """
  def user_fixture(attrs \\ %{}) do
    defaults = %{
      email: unique_email(),
      sub: unique_sub(),
      roles: [],
      oauth_tokens: %{},
      user_info: %{}
    }

    attrs = Map.merge(defaults, attrs)

    default_user_info = %{
      "given_name" => "Frank",
      "family_name" => "Grimes",
      "zip_code" => "1234",
      "city" => "Zurich",
      "street" => "Main St 1",
      "phone" => "+41791234567",
      "language" => "en",
      "email" => attrs.email,
      "sub" => attrs.sub
    }

    user_info =
      default_user_info
      |> Map.merge(attrs.user_info)
      |> put_roles_claim(attrs.roles)

    {:ok, user} =
      User
      |> Ash.Changeset.for_create(:register_with_sso, %{
        "user_info" => user_info,
        "oauth_tokens" => attrs.oauth_tokens
      })
      |> Ash.create(authorize?: false)

    user
  end

  defp put_roles_claim(user_info, []), do: user_info

  defp put_roles_claim(user_info, roles) do
    merged_roles =
      user_info
      |> Map.get("roles", [])
      |> Enum.concat(roles)
      |> Enum.uniq()

    Map.put(user_info, "roles", merged_roles)
  end

  defp unique_email do
    "user_#{System.unique_integer([:positive])}@example.com"
  end

  defp unique_sub do
    "sub_#{System.unique_integer([:positive])}"
  end
end
