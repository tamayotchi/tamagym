defmodule Tamagym.Repo.Migrations.CreateRoutines do
  use Ecto.Migration

  def change do
    create table(:routines) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :client_id, :string, null: false
      add :position, :integer, null: false
      add :name, :string, null: false
      add :emoji, :string
      add :data, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:routines, [:user_id, :client_id])
    create unique_index(:routines, [:user_id, :position])
  end
end
