defmodule Tamagym.Repo.Migrations.CreateWorkouts do
  use Ecto.Migration

  def change do
    create table(:workouts) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :client_id, :string, null: false
      add :position, :integer, null: false
      add :status, :string, null: false
      add :performed_on, :date, null: false
      add :routine_client_id, :string
      add :name, :string
      add :started_at_ms, :integer
      add :ended_at_ms, :integer
      add :body_weight, :float
      add :volume, :float
      add :data, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:workouts, [:user_id, :client_id])
    create unique_index(:workouts, [:user_id, :status, :position])
    create index(:workouts, [:user_id, :performed_on])
  end
end
