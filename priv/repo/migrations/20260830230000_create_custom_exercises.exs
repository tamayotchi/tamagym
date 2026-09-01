defmodule Tamagym.Repo.Migrations.CreateCustomExercises do
  use Ecto.Migration

  def change do
    create table(:custom_exercises) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :position, :integer, null: false
      add :exercise_id, :string, null: false
      add :name, :string, null: false
      add :data, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:custom_exercises, [:user_id, :exercise_id])
    create unique_index(:custom_exercises, [:user_id, :position])
  end
end
