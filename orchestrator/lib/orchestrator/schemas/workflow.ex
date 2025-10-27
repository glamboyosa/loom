defmodule Orchestrator.Schemas.Workflow do
  @moduledoc """
  Ecto schema for validating workflow configuration from .loom.yml
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:name, :string)
    field(:on, {:array, :string})
    field(:jobs, :map)
  end

  @doc """
  Creates a changeset for workflow validation
  """
  def changeset(workflow, attrs) do
    workflow
    |> cast(attrs, [:name, :on, :jobs])
    |> validate_required([:name, :jobs])
    |> validate_jobs()
  end

  defp validate_jobs(changeset) do
    jobs = get_field(changeset, :jobs)

    if is_map(jobs) do
      # Simple validation - check that each job has steps
      valid_jobs =
        Enum.all?(jobs, fn {_name, job_config} ->
          is_map(job_config) and Map.has_key?(job_config, "steps")
        end)

      if valid_jobs do
        changeset
      else
        add_error(changeset, :jobs, "each job must have steps")
      end
    else
      add_error(changeset, :jobs, "must be a map")
    end
  end
end
