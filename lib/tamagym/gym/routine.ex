defmodule Tamagym.Gym.Routine do
  use Ecto.Schema
  import Ecto.Changeset

  alias Tamagym.Accounts.User
  alias Tamagym.Gym.DayOverride

  schema "routines" do
    field :client_id, :string
    field :position, :integer
    field :name, :string
    field :emoji, :string
    field :data, :map, default: %{}

    belongs_to :user, User
    has_many :day_overrides, DayOverride

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(routine, attrs) do
    routine
    |> cast(attrs, [:user_id, :client_id, :position, :name, :emoji, :data])
    |> validate_required([:user_id, :client_id, :position, :name, :data])
    |> validate_number(:position, greater_than_or_equal_to: 0)
    |> unique_constraint([:user_id, :client_id])
    |> unique_constraint([:user_id, :position])
    |> foreign_key_constraint(:user_id)
  end
end
