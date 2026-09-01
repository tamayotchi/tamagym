defmodule Tamagym.Repo.Migrations.CreateBodyWeights do
  use Ecto.Migration

  def change do
    create table(:body_weights) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :position, :integer, null: false
      add :weighed_on, :date, null: false
      add :weight, :float, null: false
      add :recorded_at_ms, :integer
      add :data, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:body_weights, [:user_id, :weighed_on])
    create unique_index(:body_weights, [:user_id, :position])
  end
end
