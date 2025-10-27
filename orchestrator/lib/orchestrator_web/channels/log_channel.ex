defmodule OrchestratorWeb.LogChannel do
  @moduledoc """
  Phoenix channel for real-time log streaming to the SvelteKit UI.

  Allows clients to:
  - Subscribe to logs for specific jobs
  - Subscribe to all logs
  - Receive real-time log updates via WebSocket
  """

  use OrchestratorWeb, :channel

  @impl true
  def join("logs:" <> job_name, _payload, socket) do
    if authorized?(job_name) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def join("logs:all", _payload, socket) do
    {:ok, socket}
  end

  # Channels can be used in a request/reply fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", _payload, socket) do
    {:reply, {:ok, %{message: "pong"}}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic.
  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  # Broadcast a log entry to all connected clients
  def broadcast_log(log_entry) do
    # Broadcast to all logs channel
    OrchestratorWeb.Endpoint.broadcast("logs:all", "new_log", log_entry)

    # Broadcast to specific job channel
    OrchestratorWeb.Endpoint.broadcast("logs:#{log_entry.job_name}", "new_log", log_entry)
  end

  # Add authorization logic here as required.
  defp authorized?(_job_name) do
    # For now, allow all connections
    # In production, you might want to add authentication
    true
  end
end
