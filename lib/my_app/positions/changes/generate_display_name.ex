defmodule MyApp.Positions.Changes.GenerateDisplayName do
  @moduledoc """
  Picks a friendly "Adjective Animal" handle for a new participant.

  The word lists are identifiers, not UI copy, so they stay out of gettext.
  """
  use Ash.Resource.Change

  @adjectives ~w(Quiet Brisk Sunny Calm Swift Clever Gentle Bold Merry Wise Keen Lucky)
  @animals ~w(Fox Heron Otter Lynx Badger Finch Hare Owl Wren Deer Seal Crane)

  @impl Ash.Resource.Change
  def change(changeset, _opts, _context) do
    if Ash.Changeset.get_attribute(changeset, :display_name) do
      changeset
    else
      # ponytail: random pick + numeric suffix; the suffix keeps collisions harmless, not impossible
      name = "#{Enum.random(@adjectives)} #{Enum.random(@animals)} #{Enum.random(10..99)}"
      Ash.Changeset.force_change_attribute(changeset, :display_name, name)
    end
  end
end
