defmodule Tamagym.Gym.DayOverride do
  use Ecto.Schema
  import Ecto.Changeset

  alias Tamagym.Accounts.User
  alias Tamagym.Gym.Routine

  schema "day_overrides" do
    field :planned_on, :date
    field :kind, :string
    belongs_to :user, User
    belongs_to :routine, Routine

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(override, attrs) do
    override
    |> cast(attrs, [:user_id, :routine_id, :planned_on, :kind])
    |> validate_required([:user_id, :planned_on, :kind])
    |> validate_inclusion(:kind, ["rest", "routine"])
    |> validate_kind()
    |> unique_constraint([:user_id, :planned_on])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:routine_id)
  end

  defp validate_kind(changeset) do
    kind = get_field(changeset, :kind)
    routine_id = get_field(changeset, :routine_id)

    cond do
      kind == "routine" and is_nil(routine_id) ->
        add_error(changeset, :routine_id, "is required")

      kind == "rest" and not is_nil(routine_id) ->
        add_error(changeset, :routine_id, "must be empty")

      true ->
        changeset
    end
  end
end
