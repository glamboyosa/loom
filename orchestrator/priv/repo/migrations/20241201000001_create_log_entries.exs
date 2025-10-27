defmodule Orchestrator.Repo.Migrations.CreateLogEntries do
  use Ecto.Migration

  def change do
    create table(:log_entries) do
      add :timestamp, :utc_datetime, null: false
      add :level, :string, null: false
      add :message, :text, null: false
      add :job_name, :string, null: false
      add :step_name, :string, null: false
      add :workflow_name, :string, null: false

      timestamps()
    end

    create index(:log_entries, [:workflow_name])
    create index(:log_entries, [:job_name])
    create index(:log_entries, [:timestamp])
  end
end
