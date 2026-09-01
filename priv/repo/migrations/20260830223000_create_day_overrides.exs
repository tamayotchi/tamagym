defmodule Tamagym.Repo.Migrations.CreateDayOverrides do
  use Ecto.Migration

  def change do
    create table(:day_overrides) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :routine_id, references(:routines, on_delete: :delete_all)
      add :planned_on, :date, null: false
      add :kind, :string, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:day_overrides, [:user_id, :planned_on])
  end
end
