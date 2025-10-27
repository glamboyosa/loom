defmodule OrchestratorWeb.PageController do
  @moduledoc """
  Controller for serving the SvelteKit UI.
  """

  use OrchestratorWeb, :controller

  def index(conn, _params) do
    # Serve the SvelteKit UI
    # In production, this would serve the built SvelteKit files
    html(conn, """
    <!DOCTYPE html>
    <html>
      <head>
        <title>Loom - Self-hosted Actions Runner</title>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
          body { font-family: system-ui, sans-serif; margin: 0; padding: 2rem; }
          .container { max-width: 800px; margin: 0 auto; }
          .header { text-align: center; margin-bottom: 2rem; }
          .status { background: #f0f9ff; border: 1px solid #0ea5e9; padding: 1rem; border-radius: 0.5rem; margin-bottom: 2rem; }
          .api-list { background: #f8fafc; border: 1px solid #e2e8f0; padding: 1rem; border-radius: 0.5rem; }
          .api-item { margin: 0.5rem 0; font-family: monospace; }
          .ws-info { background: #fef3c7; border: 1px solid #f59e0b; padding: 1rem; border-radius: 0.5rem; margin-top: 2rem; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🧵 Loom</h1>
            <p>Self-hosted Actions Runner</p>
          </div>

          <div class="status">
            <h3>✅ Orchestrator Running</h3>
            <p>The Loom orchestrator is running and ready to execute workflows.</p>
          </div>

          <div class="api-list">
            <h3>📡 API Endpoints</h3>
            <div class="api-item">GET /api/status - System status</div>
            <div class="api-item">GET /api/workflows - List workflows</div>
            <div class="api-item">POST /api/workflows/:name/start - Start workflow</div>
            <div class="api-item">POST /api/workflows/:name/stop - Stop workflow</div>
            <div class="api-item">GET /api/jobs/:name/logs - Get job logs</div>
          </div>

          <div class="ws-info">
            <h3>🔌 WebSocket Connection</h3>
            <p>Connect to <code>ws://localhost:4000/socket/websocket</code> for real-time log streaming.</p>
            <p>Join channels: <code>logs:all</code> or <code>logs:job_name</code></p>
          </div>
        </div>
      </body>
    </html>
    """)
  end
end
