defmodule MyApp.Positions do
  @moduledoc """
  Who is standing where: fixed positions, anonymous participants and their check-ins.
  """

  use Ash.Domain, otp_app: :my_app

  resources do
    resource MyApp.Positions.Position
    resource MyApp.Positions.Participant
    resource MyApp.Positions.CheckIn
  end
end
