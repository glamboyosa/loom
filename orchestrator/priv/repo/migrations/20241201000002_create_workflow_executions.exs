defmodule Orchestrator.Repo.Migrations.CreateWorkflowExecutions do
  use Ecto.Migration

  def change do
    create table(:workflow_executions) do
      add :workflow_name, :string, null: false
      add :status, :string, null: false
      add :started_at, :utc_datetime, null: false
      add :completed_at, :utc_datetime
      add :config_path, :string, null: false
      add :jobs_count, :integer, null: false

      timestamps()
    end

    create index(:workflow_executions, [:workflow_name])
    create index(:workflow_executions, [:status])
    create index(:workflow_executions, [:started_at])
  end
end
