defmodule Tamagym.Gym.Workout do
  use Ecto.Schema
  import Ecto.Changeset

  alias Tamagym.Accounts.User

  schema "workouts" do
    field :client_id, :string
    field :position, :integer
    field :status, :string
    field :performed_on, :date
    field :routine_client_id, :string
    field :name, :string
    field :started_at_ms, :integer
    field :ended_at_ms, :integer
    field :body_weight, :float
    field :volume, :float
    field :data, :map, default: %{}

    belongs_to :user, User

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(workout, attrs) do
    workout
    |> cast(attrs, [
      :user_id,
      :client_id,
      :position,
      :status,
      :performed_on,
      :routine_client_id,
      :name,
      :started_at_ms,
      :ended_at_ms,
      :body_weight,
      :volume,
      :data
    ])
    |> validate_required([:user_id, :client_id, :position, :status, :performed_on, :data])
    |> validate_inclusion(:status, ["active", "completed"])
    |> validate_number(:position, greater_than_or_equal_to: 0)
    |> unique_constraint([:user_id, :client_id])
    |> unique_constraint([:user_id, :status, :position])
    |> foreign_key_constraint(:user_id)
  end
end
