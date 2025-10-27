defmodule OrchestratorWeb.WorkflowController do
  @moduledoc """
  Controller for workflow management API endpoints.
  """

  use OrchestratorWeb, :controller

  def index(conn, _params) do
    # Get current workflows from the scheduler
    case Orchestrator.Scheduler.get_workflows() do
      {:ok, workflows} ->
        # Convert workflows to JSON-serializable format
        serializable_workflows =
          Enum.map(workflows, fn workflow ->
            %{
              name: workflow.name,
              on: workflow.on,
              jobs:
                Map.new(workflow.jobs, fn {name, job} ->
                  {name,
                   %{
                     name: job.name,
                     needs: job.needs,
                     steps: job.steps,
                     state: job.state,
                     runs_on: job.runs_on
                   }}
                end)
            }
          end)

        json(conn, serializable_workflows)

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: reason})
    end
  end

  def start(conn, %{"name" => workflow_name}) do
    # Start workflow execution
    case Orchestrator.Scheduler.start_execution() do
      :ok ->
        json(conn, %{success: true, message: "Workflow #{workflow_name} started"})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: reason})
    end
  end

  def stop(conn, %{"name" => workflow_name}) do
    # Stop workflow execution
    # TODO: Implement workflow stopping
    json(conn, %{success: true, message: "Workflow #{workflow_name} stopped"})
  end

  def reload(conn, %{"file_path" => file_path}) do
    # Reload workflow from specified file
    case Orchestrator.Scheduler.load_workflow_from_file(file_path) do
      {:ok, jobs} ->
        json(conn, %{success: true, message: "Workflow reloaded with #{length(jobs)} jobs"})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: reason})
    end
  end

  def reload(conn, _params) do
    # Reload workflow from default file
    case Orchestrator.Scheduler.load_workflow_from_file("test-multi-language.loom.yml") do
      {:ok, jobs} ->
        json(conn, %{success: true, message: "Workflow reloaded with #{length(jobs)} jobs"})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: reason})
    end
  end
end
