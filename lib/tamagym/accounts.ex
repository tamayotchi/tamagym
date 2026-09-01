defmodule Tamagym.Accounts do
  @moduledoc "Email/password accounts stored in SQLite."

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Tamagym.Accounts.User
  alias Tamagym.Gym.UserSettings
  alias Tamagym.Repo

  def get_user(id), do: Repo.get(User, id)

  def get_user_by_email(email) do
    Repo.get_by(User, email: User.normalize_email(email))
  end

  def register_user(attrs) do
    Multi.new()
    |> Multi.insert(:user, User.registration_changeset(%User{}, attrs))
    |> Multi.insert(:settings, fn %{user: user} ->
      UserSettings.changeset(%UserSettings{}, %{user_id: user.id, data: %{}})
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _changes} -> {:error, changeset}
      {:error, _step, reason, _changes} -> {:error, reason}
    end
  end

  def authenticate_user(email, password) when is_binary(password) do
    user = get_user_by_email(email)

    if user && Bcrypt.verify_pass(password, user.password_hash) do
      {:ok, user}
    else
      Bcrypt.no_user_verify()
      {:error, :invalid_credentials}
    end
  end

  def authenticate_user(_email, _password) do
    Bcrypt.no_user_verify()
    {:error, :invalid_credentials}
  end

  def public_user(%User{} = user) do
    name = user.email |> String.split("@", parts: 2) |> List.first()
    %{id: user.id, email: user.email, name: name}
  end
end
