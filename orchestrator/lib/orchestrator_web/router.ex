defmodule OrchestratorWeb.Router do
  @moduledoc """
  Phoenix router for API endpoints and WebSocket channels.
  """

  use OrchestratorWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  # API routes for the SvelteKit UI
  scope "/api", OrchestratorWeb do
    pipe_through(:api)

    # System status
    get("/status", StatusController, :index)

    # Workflow management
    get("/workflows", WorkflowController, :index)
    post("/workflows/:name/start", WorkflowController, :start)
    post("/workflows/:name/stop", WorkflowController, :stop)
    post("/workflows/reload", WorkflowController, :reload)

    # Job management
    get("/jobs/:name/logs", JobController, :logs)
    get("/jobs/:name/status", JobController, :status)
  end

  # WebSocket channels
  scope "/", OrchestratorWeb do
    # Use the default browser stack
    pipe_through([:fetch_session, :protect_from_forgery])

    # Serve the SvelteKit UI
    get("/*path", PageController, :index)
  end
end
