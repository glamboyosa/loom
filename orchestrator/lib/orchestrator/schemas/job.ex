defmodule Orchestrator.Schemas.Job do
  @moduledoc """
  Ecto schema for validating individual job configuration
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:runs_on, :string)
    field(:needs, {:array, :string})
    field(:steps, {:array, :map})
  end

  @doc """
  Creates a changeset for job validation
  """
  def changeset(job, attrs) do
    job
    |> cast(attrs, [:runs_on, :needs, :steps])
    |> validate_required([:steps])
    |> validate_steps()
  end

  defp validate_steps(changeset) do
    steps = get_field(changeset, :steps)

    if is_list(steps) do
      # Validate each step has required fields
      valid_steps = Enum.all?(steps, &validate_step/1)

      if valid_steps do
        changeset
      else
        add_error(changeset, :steps, "each step must have 'name' and 'run' fields")
      end
    else
      add_error(changeset, :steps, "must be a list")
    end
  end

  defp validate_step(step) when is_map(step) do
    Map.has_key?(step, "name") and Map.has_key?(step, "run")
  end

  defp validate_step(_), do: false
end
