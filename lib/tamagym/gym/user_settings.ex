defmodule Tamagym.Gym.UserSettings do
  use Ecto.Schema
  import Ecto.Changeset

  alias Tamagym.Accounts.User

  schema "user_settings" do
    field :data, :map, default: %{}
    belongs_to :user, User

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(settings, attrs) do
    settings
    |> cast(attrs, [:user_id, :data])
    |> validate_required([:user_id, :data])
    |> unique_constraint(:user_id)
    |> foreign_key_constraint(:user_id)
  end
end
