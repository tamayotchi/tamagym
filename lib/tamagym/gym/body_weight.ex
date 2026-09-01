defmodule Tamagym.Gym.BodyWeight do
  use Ecto.Schema
  import Ecto.Changeset

  alias Tamagym.Accounts.User

  schema "body_weights" do
    field :position, :integer
    field :weighed_on, :date
    field :weight, :float
    field :recorded_at_ms, :integer
    field :data, :map, default: %{}

    belongs_to :user, User

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(body_weight, attrs) do
    body_weight
    |> cast(attrs, [:user_id, :position, :weighed_on, :weight, :recorded_at_ms, :data])
    |> validate_required([:user_id, :position, :weighed_on, :weight, :data])
    |> validate_number(:position, greater_than_or_equal_to: 0)
    |> validate_number(:weight, greater_than: 0)
    |> unique_constraint([:user_id, :weighed_on])
    |> unique_constraint([:user_id, :position])
    |> foreign_key_constraint(:user_id)
  end
end
