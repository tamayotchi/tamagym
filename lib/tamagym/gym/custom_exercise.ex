defmodule Tamagym.Gym.CustomExercise do
  use Ecto.Schema
  import Ecto.Changeset

  alias Tamagym.Accounts.User

  schema "custom_exercises" do
    field :position, :integer
    field :exercise_id, :string
    field :name, :string
    field :data, :map, default: %{}

    belongs_to :user, User

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(exercise, attrs) do
    exercise
    |> cast(attrs, [:user_id, :position, :exercise_id, :name, :data])
    |> validate_required([:user_id, :position, :exercise_id, :name, :data])
    |> validate_number(:position, greater_than_or_equal_to: 0)
    |> unique_constraint([:user_id, :exercise_id])
    |> unique_constraint([:user_id, :position])
    |> foreign_key_constraint(:user_id)
  end
end
