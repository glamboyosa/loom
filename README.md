# 🧵 Loom - File-Watching Workflow Runner

> **Loom** is a lightweight, file-watching workflow runner that executes jobs defined in `.loom.yml` files. Think GitHub Actions, but local and file-driven.

## 🎯 What is Loom?

Loom watches a `.loom.yml` file in your project directory and automatically executes workflows when the file changes. Each job runs in a Docker container (or subprocess) with full dependency management, parallel execution, and real-time logging.

### Key Features

- 🔍 **File Watching**: Automatically detects changes to `.loom.yml`
- 🐳 **Docker Integration**: Each job runs in isolated containers
- 📊 **Dependency Management**: Smart DAG-based job scheduling
- ⚡ **Parallel Execution**: Independent jobs run simultaneously
- 📝 **Real-time Logs**: Live output to console and web dashboard
- 🛡️ **Type Safety**: Robust validation with clear error messages

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Orchestrator  │    │   Job Runner    │
│   Dashboard     │◄──►│   (Elixir)      │◄──►│   (Docker)      │
│   (Web UI)      │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │   File Watcher  │
                       │   (.loom.yml)   │
                       └─────────────────┘
```

### Components

#### 🎛️ **Orchestrator** (This Repository)

- **Language**: Elixir/OTP
- **Purpose**: Core workflow engine
- **Features**:
  - YAML parsing and validation
  - Dependency graph management
  - Job scheduling and execution
  - State management and coordination

#### 🖥️ **Frontend Dashboard** (Future)

- **Language**: React/TypeScript
- **Purpose**: Web-based monitoring interface
- **Features**:
  - Real-time job status
  - Live log streaming
  - Workflow visualization
  - Historical execution data

#### 🐳 **Job Runner** (Docker)

- **Purpose**: Isolated job execution
- **Features**:
  - Container-based isolation
  - Environment consistency
  - Resource management
  - Log capture and streaming

## 📝 Workflow Definition

Define your workflows in `.loom.yml`:

```yaml
name: "My Project Workflow"
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Install dependencies
        run: npm install
      - name: Build project
        run: npm run build

  test:
    needs: [build]
    runs-on: ubuntu-latest
    steps:
      - name: Run tests
        run: npm test

  lint:
    needs: [build]
    runs-on: ubuntu-latest
    steps:
      - name: Run linter
        run: npm run lint

  deploy:
    needs: [test, lint]
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to staging
        run: ./deploy.sh
```

### Execution Flow

1. **File Change**: Modify `.loom.yml`
2. **Parse & Validate**: Orchestrator validates the workflow
3. **Build DAG**: Create dependency graph
4. **Execute**: Run jobs in optimal order
5. **Monitor**: Track progress and logs

### Dependency Graph

```
    build
   /     \
  test   lint
   \     /
    deploy
```

- `build` runs first (no dependencies)
- `test` and `lint` run in parallel (both depend on `build`)
- `deploy` runs last (depends on both `test` and `lint`)

## 🚀 Quick Start

### 🐳 **Option 1: Docker Hub (Instant)**

**Perfect for**: Quick testing, demos, and trying Loom

```bash
# One-line install
curl -sSL https://raw.githubusercontent.com/glamboyosa/loom/main/run-loom.sh | bash

# Or manual Docker run
docker run -d \
  --name loom \
  -p 4000:4000 -p 5173:5173 \
  -v "$(pwd)/loom-data:/app/data" \
  -v "/var/run/docker.sock:/var/run/docker.sock" \
  -v "$(pwd):/workspace" \
  --restart unless-stopped \
  loom/orchestrator:latest
```

**Access**: http://localhost:5173 (Dashboard) + http://localhost:4000 (API)

### 📦 **Option 2: Clone + Docker (Customizable)**

**Perfect for**: Development, customization, and contributing

```bash
# Clone and start
git clone https://github.com/glamboyosa/loom.git
cd loom
docker-compose up -d

# Or development mode
./dev.sh
```

**Access**: http://localhost:5173 (Dashboard) + http://localhost:4000 (API)

### 🔧 **Option 3: Development Mode**

**Perfect for**: Contributors and advanced users

```bash
# Backend
cd orchestrator
mix deps.get && mix ecto.setup && mix phx.server

# Frontend (new terminal)
cd ui
pnpm install && pnpm dev
```

**Access**: http://localhost:5173 (Dashboard) + http://localhost:4000 (API)

## 🎯 **What You Get**

### ✅ **Complete Workflow Engine**

- **File Watching**: Automatically detects `.loom.yml` changes
- **Job Scheduling**: Runs jobs based on dependencies
- **Docker Execution**: Isolated job execution in containers
- **Real-time Logs**: Live streaming via WebSocket

### ✅ **Multi-Language Support**

- **Node.js** (16, 18, 20, 22)
- **Python** (3.9, 3.10, 3.11, 3.12)
- **Go** (1.21, 1.22, 1.23)
- **Java** (11, 17, 21)
- **PHP** (8.1, 8.2, 8.3)
- **Ruby** (3.1, 3.2, 3.3)
- **Rust** (1.75)
- **.NET** (6, 7, 8)
- **Ubuntu** (20.04, 22.04, latest)
- **Custom** Docker images

### ✅ **GitHub Actions Compatible**

- Same workflow syntax as GitHub Actions
- Workspace mounting (`/workspace` in containers)
- Environment variables and secrets
- Matrix builds and parallel jobs

## 🎮 **Try It Out**

Create a `.loom.yml` file in your project:

```yaml
name: "My First Workflow"
on: [push, pull_request]

jobs:
  hello-world:
    runs-on: ubuntu-latest
    steps:
      - name: Say hello
        run: echo "Hello from Loom!"

      - name: Show system info
        run: |
          echo "OS: $(uname -a)"
          echo "Current directory: $(pwd)"
          echo "Files in workspace:"
          ls -la

  node-example:
    runs-on: node-18
    steps:
      - name: Node.js version
        run: node --version

      - name: Create and run script
        run: |
          echo 'console.log("Hello from Node.js!");' > hello.js
          node hello.js

  python-example:
    runs-on: python-3.11
    steps:
      - name: Python version
        run: python --version

      - name: Create and run script
        run: |
          echo 'print("Hello from Python!")' > hello.py
          python hello.py
```

**Loom will automatically:**

1. Watch for file changes
2. Reload the workflow
3. Execute jobs in Docker containers
4. Stream logs to the dashboard
5. Show real-time progress

## 🔧 **Development Commands**

```bash
make help        # Show all commands
make dev         # Start interactive development
make dev-full    # Start full development environment (backend + frontend)
make test-parser # Test YAML parsing
make compile     # Compile project
make clean       # Clean build artifacts
```

## 🔧 **Troubleshooting**

### Common Issues

**Port already in use:**

```bash
# Check what's using the ports
lsof -i :4000
lsof -i :5173

# Kill the processes
sudo kill -9 <PID>
```

**Docker not running:**

```bash
# Start Docker Desktop or Docker daemon
sudo systemctl start docker  # Linux
```

**Permission denied (Docker):**

```bash
# Fix Docker socket permissions
sudo chmod 666 /var/run/docker.sock
```

**Node.js version issues:**

```bash
# Use nvm to manage Node.js versions
nvm install 22
nvm use 22
nvm alias default 22
```

### Getting Help

1. **Check logs**: `docker logs loom`
2. **Verify services**: Ensure ports 4000 and 5173 are available
3. **Docker status**: Verify Docker is running and accessible
4. **File permissions**: Ensure Docker can access your workspace

## 🔧 Configuration

### Environment Variables

```bash
# Workspace path (default: current directory)
export LOOM_WORKSPACE_PATH="/path/to/project"

# Config file path (default: .loom.yml)
export LOOM_CONFIG_PATH=".loom.yml"

# Log level (default: info)
export LOOM_LOG_LEVEL="debug"
```

### Docker Configuration

```yaml
# .loom.yml
jobs:
  my-job:
    runs-on: ubuntu-latest
    container:
      image: node:18
      volumes:
        - .:/workspace
      working-directory: /workspace
    steps:
      - name: Install dependencies
        run: npm install
```

## 📊 Monitoring & Logs

### Console Output

```
🔍 Watcher: Monitoring .loom.yml
📁 Watcher: Config file changed: .loom.yml
✅ Watcher: Workflow reloaded with 4 jobs
🚀 Scheduler: Starting execution...
📋 Scheduler: Found 1 ready jobs
🏃 Runner: Starting job 'build'
✅ Runner: Job 'build' completed
```

### Web Dashboard (Future)

- Real-time job status
- Live log streaming
- Workflow visualization
- Performance metrics
- Historical data

## 🛠️ Development

### Project Structure

```
loom/
├── orchestrator/          # Elixir backend
│   ├── lib/
│   │   └── orchestrator/
│   │       ├── schemas/   # Ecto validation schemas
│   │       ├── scheduler/ # Job scheduling
│   │       ├── runner/    # Job execution
│   │       └── watcher/   # File monitoring
│   ├── test/
│   └── mix.exs
├── frontend/              # React dashboard (future)
└── README.md
```

### Key Technologies

- **Elixir/OTP**: Fault-tolerant, concurrent backend
- **Ecto**: Data validation and transformation
- **libgraph**: Dependency graph management
- **Docker**: Containerized job execution
- **React**: Web dashboard (planned)

### Testing

```bash
# Run tests
mix test

# Test specific components
mix run test_scheduler.exs
mix run test_communication.exs
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

### Development Setup

```bash
# Install dependencies
mix deps.get

# Run tests
mix test

# Start development server
make dev
```

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

**Loom** - Weaving workflows together, one file at a time. 🧵
