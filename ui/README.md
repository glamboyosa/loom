# 🖥️ Loom UI - Web Dashboard

A modern SvelteKit dashboard for monitoring and controlling your Loom self-hosted Actions runner.

## 🚀 Features

- **Real-time Dashboard**: Monitor workflow execution and job status
- **Live Log Streaming**: WebSocket-based real-time log viewing
- **Workflow Management**: Start, stop, and monitor workflows
- **Job Visualization**: See job dependencies and execution order
- **Modern UI**: Built with SvelteKit, TypeScript, and TailwindCSS

## 🛠️ Tech Stack

- **SvelteKit**: Full-stack web framework
- **TypeScript**: Type-safe development
- **TailwindCSS**: Utility-first CSS framework
- **Remote Functions**: Type-safe server communication
- **WebSocket**: Real-time log streaming
- **Zod**: Schema validation

## 📦 Installation

```bash
# Install dependencies
pnpm install

# Start development server
pnpm dev

# Build for production
pnpm build

# Preview production build
pnpm preview
```

## 🔧 Configuration

The UI connects to the Elixir orchestrator via:

1. **HTTP API**: For workflow management and status
2. **WebSocket**: For real-time log streaming

Update the connection URLs in:

- `src/lib/orchestrator.remote.ts` - API endpoints
- `src/lib/stores/websocket.ts` - WebSocket endpoint

## 🏗️ Architecture

### Remote Functions

Using SvelteKit's [remote functions](https://svelte.dev/docs/kit/remote-functions) for type-safe server communication:

```typescript
// Get system status
const status = await getSystemStatus();

// Start workflow
await startWorkflow({ workflow_name: 'my-workflow' });

// Get job logs
const logs = await getJobLogs({ job_name: 'build' });
```

### WebSocket Integration

Real-time log streaming with automatic reconnection:

```typescript
// Connect to orchestrator WebSocket
connectWebSocket();

// Subscribe to specific job logs
subscribeToJobLogs('build');

// Listen to log updates
$: logs = $logEntries;
```

## 📱 Pages

### Dashboard (`/`)

- System status overview
- Workflow visualization
- Job dependency graph
- Start/stop controls

### Live Logs (`/logs`)

- Real-time log streaming
- Job-specific log filtering
- Log level filtering
- Auto-scroll functionality

## 🔌 API Integration

The UI communicates with the Elixir orchestrator through:

### HTTP Endpoints

- `GET /api/status` - System status
- `GET /api/workflows` - List workflows
- `POST /api/workflows/start` - Start workflow
- `POST /api/workflows/stop` - Stop workflow

### WebSocket Endpoints

- `ws://localhost:4000/ws/logs` - Real-time log streaming

## 🎨 UI Components

- **Navigation**: Top navigation bar
- **Job Cards**: Visual job status and details
- **Log Viewer**: Real-time log display with filtering
- **Status Indicators**: System and WebSocket status

## 🚀 Development

```bash
# Start with hot reload
pnpm dev

# Type checking
pnpm check

# Linting
pnpm lint

# Testing
pnpm test
```

## 📦 Production Deployment

```bash
# Build optimized bundle
pnpm build

# Start production server
pnpm start
```

The built application can be deployed to any Node.js hosting platform or served as static files.

## 🔗 Integration with Elixir Orchestrator

This UI is designed to work with the Loom Elixir orchestrator:

1. **Start the orchestrator**: `cd ../orchestrator && make dev`
2. **Start the UI**: `pnpm dev`
3. **Access dashboard**: http://localhost:5173

The UI will automatically connect to the orchestrator's WebSocket for real-time updates.

---

**Loom UI** - Beautiful monitoring for your self-hosted Actions runner 🧵
