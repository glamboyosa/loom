defmodule Orchestrator.Schemas.WorkflowExecution do
  @moduledoc """
  Database schema for storing workflow execution history.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  schema "workflow_executions" do
    field :workflow_name, :string
    field :status, :string  # "running", "completed", "failed"
    field :started_at, :utc_datetime
    field :completed_at, :utc_datetime
    field :config_path, :string
    field :jobs_count, :integer

    timestamps()
  end

  @doc false
  def changeset(workflow_execution, attrs) do
    workflow_execution
    |> cast(attrs, [:workflow_name, :status, :started_at, :completed_at, :config_path, :jobs_count])
    |> validate_required([:workflow_name, :status, :started_at, :config_path, :jobs_count])
    |> validate_inclusion(:status, ["running", "completed", "failed"])
  end
end
