[
  # ash_authentication_phoenix 2.17.2 injects `@type user :: Ash.Resource.record()`
  # via `use AshAuthentication.Phoenix.Controller`, but ash >= 3.29 no longer
  # defines that type on OTP >= 29. Fixed upstream in ash_authentication_phoenix 3.0.
  {"lib/ash_authentication_phoenix/controller.ex", :unknown_type}
]
