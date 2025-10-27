defmodule Orchestrator.Application do
  @moduledoc """
  The Orchestrator Application.

  This module starts the entire system including:
  - Ecto repository for SQLite database
  - Phoenix endpoint for web interface
  - All GenServers (Scheduler, Runner, DockerRunner, Watcher)
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Orchestrator.Repo,

      # Start the Phoenix PubSub system
      {Phoenix.PubSub, name: Orchestrator.PubSub},

      # Start the Phoenix endpoint
      OrchestratorWeb.Endpoint,

      # Start our core GenServers
      Orchestrator.Scheduler,
      Orchestrator.Runner,
      Orchestrator.DockerRunner,
      Orchestrator.Watcher
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Orchestrator.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    OrchestratorWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
