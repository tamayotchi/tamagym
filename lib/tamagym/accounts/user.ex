defmodule Tamagym.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias Tamagym.Gym.{
    BodyWeight,
    CustomExercise,
    DayOverride,
    Routine,
    UserSettings,
    Workout
  }

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :password_hash, :string, redact: true

    has_one :settings, UserSettings
    has_many :routines, Routine
    has_many :day_overrides, DayOverride
    has_many :workouts, Workout
    has_many :body_weights, BodyWeight
    has_many :custom_exercises, CustomExercise

    timestamps(type: :utc_datetime_usec)
  end

  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password])
    |> update_change(:email, &normalize_email/1)
    |> validate_required([:email, :password])
    |> validate_length(:email, max: 160)
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/,
      message: "must be a valid email address"
    )
    |> validate_length(:password, min: 8, max: 72)
    |> validate_change(:password, fn :password, password ->
      if byte_size(password) <= 72, do: [], else: [password: "must be at most 72 bytes"]
    end)
    |> unique_constraint(:email, name: :users_email_index)
    |> hash_password()
  end

  def normalize_email(email) when is_binary(email) do
    email
    |> String.trim()
    |> String.downcase()
  end

  def normalize_email(_), do: ""

  defp hash_password(%Ecto.Changeset{valid?: true} = changeset) do
    put_change(changeset, :password_hash, Bcrypt.hash_pwd_salt(get_change(changeset, :password)))
  end

  defp hash_password(changeset), do: changeset
end
