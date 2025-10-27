defmodule OrchestratorWeb.JobController do
  @moduledoc """
  Controller for job management API endpoints.
  """

  use OrchestratorWeb, :controller
  import Ecto.Query
  alias Orchestrator.Repo
  alias Orchestrator.Schemas.LogEntry

  def logs(conn, %{"name" => job_name}) do
    # Get logs for a specific job from the database
    logs = Repo.all(
      from l in LogEntry,
      where: l.job_name == ^job_name,
      order_by: [desc: l.timestamp],
      limit: 100
    )

    # Convert to the format expected by the UI
    formatted_logs = Enum.map(logs, fn log ->
      %{
        timestamp: log.timestamp,
        level: log.level,
        message: log.message,
        job_name: log.job_name,
        step_name: log.step_name
      }
    end)

    json(conn, formatted_logs)
  end

  def status(conn, %{"name" => job_name}) do
    # Get job status from the scheduler
    case Orchestrator.Scheduler.get_job_status(job_name) do
      {:ok, status} ->
        json(conn, status)
      {:error, reason} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: reason})
    end
  end
end
