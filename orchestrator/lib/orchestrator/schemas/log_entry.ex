defmodule Orchestrator.Schemas.LogEntry do
  @moduledoc """
  Database schema for storing log entries from job execution.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  schema "log_entries" do
    field :timestamp, :utc_datetime
    field :level, :string
    field :message, :string
    field :job_name, :string
    field :step_name, :string
    field :workflow_name, :string

    timestamps()
  end

  @doc false
  def changeset(log_entry, attrs) do
    log_entry
    |> cast(attrs, [:timestamp, :level, :message, :job_name, :step_name, :workflow_name])
    |> validate_required([:timestamp, :level, :message, :job_name, :step_name, :workflow_name])
    |> validate_inclusion(:level, ["info", "error", "warn", "debug"])
  end
end
