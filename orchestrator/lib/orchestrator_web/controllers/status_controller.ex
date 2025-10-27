defmodule OrchestratorWeb.StatusController do
  @moduledoc """
  Controller for system status API endpoints.
  """

  use OrchestratorWeb, :controller

  def index(conn, _params) do
    # Get status from all GenServers
    status = %{
      scheduler: get_component_status(Orchestrator.Scheduler),
      runner: get_component_status(Orchestrator.Runner),
      docker_runner: get_component_status(Orchestrator.DockerRunner),
      watcher: get_component_status(Orchestrator.Watcher)
    }

    json(conn, status)
  end

  defp get_component_status(module) do
    case Process.whereis(module) do
      nil -> "stopped"
      _pid -> "running"
    end
  end
end
