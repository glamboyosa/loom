defmodule Orchestrator.ConfigParser do
  @moduledoc """
  Parses .loom.yml files and converts them to Job structs using Ecto validation
  """

  alias Orchestrator.Schemas.Workflow
  alias Orchestrator.Job

  @doc """
  Parses YAML content and returns a list of Job structs
  """
  def parse_yaml(content) do
    with {:ok, yaml_data} <- YamlElixir.read_from_string(content),
         {:ok, workflow} <- validate_workflow(yaml_data),
         {:ok, jobs} <- convert_to_jobs(workflow) do
      {:ok, jobs}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Parses a YAML file from disk
  """
  def parse_file(file_path) do
    case File.read(file_path) do
      {:ok, content} -> parse_yaml(content)
      {:error, reason} -> {:error, "Failed to read file: #{reason}"}
    end
  end

  defp validate_workflow(yaml_data) do
    changeset = Workflow.changeset(%Workflow{}, yaml_data)

    if changeset.valid? do
      {:ok, Ecto.Changeset.apply_changes(changeset)}
    else
      errors = format_changeset_errors(changeset)
      {:error, "Validation failed: #{errors}"}
    end
  end

  defp convert_to_jobs(workflow) do
    jobs =
      workflow.jobs
      |> Enum.map(fn {name, job_config} ->
        Job.new(
          name,
          job_config["steps"] || [],
          needs: job_config["needs"] || [],
          runs_on: job_config["runs-on"] || "ubuntu-latest"
        )
      end)

    {:ok, jobs}
  end

  defp format_changeset_errors(changeset) do
    changeset.errors
    |> Enum.map(fn {field, {message, _}} -> "#{field}: #{message}" end)
    |> Enum.join(", ")
  end
end
