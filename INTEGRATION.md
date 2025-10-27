# 🔗 Integration Guide - Loom UI ↔ Elixir Orchestrator

This guide explains how to connect the SvelteKit UI with the Elixir orchestrator for a complete self-hosted Actions runner experience.

## 🏗️ Architecture Overview

```
┌─────────────────┐    HTTP/WebSocket    ┌─────────────────┐
│   SvelteKit UI  │◄────────────────────►│ Elixir Orchestrator │
│   (Frontend)    │                      │   (Backend)     │
└─────────────────┘                      └─────────────────┘
         │                                        │
         │                                        │
         ▼                                        ▼
┌─────────────────┐                      ┌─────────────────┐
│   Web Browser   │                      │   Docker Jobs   │
│   (User)        │                      │   (Execution)   │
└─────────────────┘                      └─────────────────┘
```

## 🚀 Quick Start

### 1. Start the Elixir Orchestrator

```bash
cd orchestrator
make dev

# In IEx:
Orchestrator.start()
```

### 2. Start the SvelteKit UI

```bash
cd ui
pnpm dev
```

### 3. Access the Dashboard

- **UI Dashboard**: http://localhost:5173
- **Elixir Orchestrator**: Running in IEx

## 🔌 Communication Methods

### 1. Remote Functions (HTTP)

The UI uses SvelteKit's [remote functions](https://svelte.dev/docs/kit/remote-functions) to communicate with the orchestrator:

```typescript
// Get system status
const status = await getSystemStatus();

// Start workflow
await startWorkflow({ workflow_name: "my-workflow" });

// Get job logs
const logs = await getJobLogs({ job_name: "build" });
```

**Current Implementation**: Mock data in `src/lib/orchestrator.remote.ts`

### 2. WebSocket (Real-time)

Real-time log streaming via WebSocket:

```typescript
// Connect to orchestrator
connectWebSocket();

// Subscribe to job logs
subscribeToJobLogs("build");

// Listen to updates
$: logs = $logEntries;
```

**Current Implementation**: Mock WebSocket in `src/lib/stores/websocket.ts`

## 🛠️ Integration Steps

### Step 1: Add HTTP API to Elixir Orchestrator

Create API endpoints in the Elixir orchestrator:

```elixir
# lib/orchestrator_web/router.ex
defmodule OrchestratorWeb.Router do
  use Phoenix.Router

  scope "/api", OrchestratorWeb do
    get "/status", StatusController, :index
    get "/workflows", WorkflowController, :index
    post "/workflows/:name/start", WorkflowController, :start
    post "/workflows/:name/stop", WorkflowController, :stop
    get "/jobs/:name/logs", JobController, :logs
  end
end
```

### Step 2: Add WebSocket to Elixir Orchestrator

```elixir
# lib/orchestrator_web/channels/log_channel.ex
defmodule OrchestratorWeb.LogChannel do
  use Phoenix.Channel

  def join("logs:" <> job_name, _payload, socket) do
    {:ok, socket}
  end

  def handle_info({:log_data, log_entry}, socket) do
    push(socket, "new_log", log_entry)
    {:noreply, socket}
  end
end
```

### Step 3: Update UI Remote Functions

Replace mock implementations with real API calls:

```typescript
// src/lib/orchestrator.remote.ts
export const getSystemStatus = query(async () => {
  const response = await fetch("http://localhost:4000/api/status");
  return response.json();
});

export const startWorkflow = command(
  z.object({ workflow_name: z.string() }),
  async ({ workflow_name }) => {
    const response = await fetch(
      `http://localhost:4000/api/workflows/${workflow_name}/start`,
      {
        method: "POST",
      }
    );
    return response.json();
  }
);
```

### Step 4: Update WebSocket Connection

```typescript
// src/lib/stores/websocket.ts
export function connectWebSocket() {
  ws = new WebSocket("ws://localhost:4000/socket/websocket");

  ws.onopen = () => {
    // Join log channel
    ws.send(
      JSON.stringify({
        topic: "logs:all",
        event: "phx_join",
        payload: {},
      })
    );
  };
}
```

## 📊 Data Flow

### 1. Workflow Management

```
User clicks "Start" → UI calls startWorkflow() → HTTP POST to orchestrator →
Orchestrator starts execution → WebSocket broadcasts status updates → UI updates
```

### 2. Real-time Logs

```
Docker container outputs log → Orchestrator captures log →
WebSocket broadcasts to UI → UI displays in real-time
```

### 3. Job Status Updates

```
Job completes → Orchestrator updates state → WebSocket broadcasts →
UI updates job status → Triggers next jobs
```

## 🔧 Configuration

### Environment Variables

**UI (.env)**

```bash
VITE_ORCHESTRATOR_URL=http://localhost:4000
VITE_WS_URL=ws://localhost:4000/socket/websocket
```

**Orchestrator (config/config.exs)**

```elixir
config :orchestrator, OrchestratorWeb.Endpoint,
  http: [port: 4000],
  url: [host: "localhost", port: 4000]
```

## 🧪 Testing Integration

### 1. Test HTTP API

```bash
# Test system status
curl http://localhost:4000/api/status

# Test workflow start
curl -X POST http://localhost:4000/api/workflows/test/start
```

### 2. Test WebSocket

```javascript
// Browser console
const ws = new WebSocket("ws://localhost:4000/socket/websocket");
ws.onmessage = (event) => console.log(JSON.parse(event.data));
```

### 3. Test Complete Flow

1. Start orchestrator: `Orchestrator.start()`
2. Start UI: `pnpm dev`
3. Open dashboard: http://localhost:5173
4. Click "Start" on a workflow
5. Watch real-time logs in `/logs` page

## 🚀 Production Deployment

### 1. Build UI

```bash
cd ui
pnpm build
```

### 2. Deploy Orchestrator

```bash
cd orchestrator
MIX_ENV=prod mix release
```

### 3. Configure Reverse Proxy

```nginx
# nginx.conf
location / {
    proxy_pass http://localhost:5173;  # SvelteKit UI
}

location /api {
    proxy_pass http://localhost:4000;  # Elixir API
}

location /socket {
    proxy_pass http://localhost:4000;  # WebSocket
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
}
```

## 🔍 Debugging

### Common Issues

1. **CORS Errors**: Configure CORS in Elixir orchestrator
2. **WebSocket Connection Failed**: Check WebSocket endpoint URL
3. **API 404**: Verify API routes are defined
4. **Logs Not Streaming**: Check WebSocket channel subscriptions

### Debug Tools

```typescript
// Enable debug logging
localStorage.setItem("debug", "websocket,api");

// Check WebSocket connection
console.log("WS State:", ws?.readyState);
```

## 📚 Next Steps

1. **Add Authentication**: Secure API endpoints
2. **Add Persistence**: Store logs in database
3. **Add Metrics**: Performance monitoring
4. **Add Notifications**: Email/Slack alerts
5. **Add Multi-tenancy**: Multiple projects support

---

**Ready to build your self-hosted Actions runner!** 🧵
