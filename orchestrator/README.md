# 🎛️ Orchestrator - Loom's Core Engine

The Orchestrator is the heart of Loom, built in Elixir/OTP. It handles workflow parsing, dependency management, job scheduling, and component coordination.

## 🎯 What Does the Orchestrator Do?

The Orchestrator is responsible for:

1. **📄 Parsing** `.loom.yml` files with robust validation
2. **📊 Building** dependency graphs (DAGs) from job definitions
3. **⚡ Scheduling** jobs in optimal execution order
4. **🔄 Coordinating** between Watcher, Scheduler, and Runner components
5. **🛡️ Managing** job states and error handling

## 🏗️ Architecture

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│   Watcher   │───▶│  Scheduler   │───▶│   Runner    │
│             │    │              │    │             │
│ Watches     │    │ Manages DAG  │    │ Executes    │
│ .loom.yml   │    │ & Job States │    │ Jobs        │
└─────────────┘    └──────────────┘    └─────────────┘
       │                   ▲                   │
       │                   │                   │
       └───────────────────┼───────────────────┘
                           │
                    Reports completion
```

## 📁 Project Structure

```
lib/orchestrator/
├── schemas/              # Ecto validation schemas
│   ├── workflow.ex      # Workflow-level validation
│   └── job.ex           # Job-level validation
├── scheduler/           # Job scheduling and state management
│   └── scheduler.ex     # Main scheduler GenServer
├── runner/              # Job execution coordination
│   └── runner.ex        # Runner GenServer
├── watcher/             # File monitoring
│   └── watcher.ex       # File watcher GenServer
├── job.ex               # Job struct definition
├── config_parser.ex     # YAML parsing and validation
├── dag.ex               # Dependency graph management
└── application.ex       # OTP application entry point
```

## 🔧 Key Components

### 1. **Config Parser** (`config_parser.ex`)

- Parses YAML files using `yaml_elixir`
- Validates data with Ecto schemas
- Converts to Job structs
- Provides clear error messages

### 2. **DAG Manager** (`dag.ex`)

- Builds dependency graphs from jobs
- Detects circular dependencies
- Calculates execution order
- Finds ready-to-run jobs

### 3. **Scheduler** (`scheduler/scheduler.ex`)

- Manages workflow state
- Coordinates job execution
- Tracks job completion
- Handles error recovery

### 4. **Runner** (`runner/runner.ex`)

- Executes individual jobs
- Reports completion status
- Handles job failures
- Manages resource allocation

### 5. **Watcher** (`watcher/watcher.ex`)

- Monitors `.loom.yml` for changes
- Triggers workflow reloads
- Handles file system events

## 🚀 Getting Started

### Prerequisites

- Elixir 1.17+
- Mix build tool

### Installation

```bash
# Install dependencies
mix deps.get

# Compile
mix compile
```

### Development Commands

```bash
# Show all available commands
make help

# Start interactive development
make dev

# Test YAML parsing
make test-parser

# Run specific tests
mix run test_scheduler.exs
mix run test_communication.exs
```

## 📊 Data Flow

### 1. YAML Parsing

```
.loom.yml → YamlElixir → Raw Map → Ecto Schema → Validated Struct
```

### 2. Job Creation

```
Validated Struct → Job.new() → Job Structs → DAG.build() → Graph
```

### 3. Execution

```
Graph → Ready Jobs → Runner → Completion → Next Ready Jobs
```

## 🔍 Example Usage

### Basic Workflow

```elixir
# Start all components
{:ok, _} = Orchestrator.Scheduler.start_link()
{:ok, _} = Orchestrator.Runner.start_link()
{:ok, _} = Orchestrator.Watcher.start_link()

# Load workflow
{:ok, jobs} = Orchestrator.Scheduler.load_workflow_from_file("test.loom.yml")

# Get ready jobs
{:ok, ready_jobs} = Orchestrator.Scheduler.get_ready_jobs()

# Start execution
Orchestrator.Scheduler.start_execution()
```

### Manual Job Execution

```elixir
# Create a job
job = Orchestrator.Job.new("test", [%{name: "Run tests", run: "npm test"}])

# Run it
Orchestrator.Runner.run_job(job)

# Mark as completed
Orchestrator.Scheduler.mark_job_completed("test")
```

## 🧪 Testing

### Test Files

- `test_scheduler.exs` - Scheduler GenServer functionality
- `test_communication.exs` - Component communication
- `debug_parsing.exs` - YAML parsing pipeline
- `debug_dag.exs` - Dependency graph operations

### Running Tests

```bash
# Test specific functionality
mix run test_scheduler.exs

# Test communication between components
mix run test_communication.exs

# Debug parsing process
mix run debug_parsing.exs

# Debug DAG operations
mix run debug_dag.exs
```

## 🔧 Configuration

### Environment Variables

```bash
# Workspace path for jobs
export LOOM_WORKSPACE_PATH="/path/to/project"

# Config file to watch
export LOOM_CONFIG_PATH=".loom.yml"

# Log level
export LOOM_LOG_LEVEL="debug"
```

### GenServer Options

```elixir
# Start with custom options
Orchestrator.Watcher.start_link(config_path: "custom.loom.yml")
Orchestrator.Runner.start_link(workspace_path: "/custom/path")
```

## 📚 Key Concepts

### Ecto Schemas

- **Purpose**: Data validation and transformation
- **Benefits**: Type safety, clear error messages
- **Usage**: Validates YAML structure before processing

### Dependency Graphs (DAGs)

- **Purpose**: Manage job dependencies and execution order
- **Benefits**: Prevents cycles, enables parallel execution
- **Usage**: Determines which jobs can run simultaneously

### GenServer Communication

- **Purpose**: Coordinate between components
- **Benefits**: Fault tolerance, state management
- **Usage**: Synchronous and asynchronous message passing

### OTP Supervision

- **Purpose**: Handle process failures gracefully
- **Benefits**: Automatic restart, fault isolation
- **Usage**: Supervises all GenServer processes

## 🐛 Debugging

### Common Issues

1. **YAML Parsing Errors**

   ```bash
   # Check YAML syntax
   mix run debug_parsing.exs
   ```

2. **Dependency Cycles**

   ```bash
   # Check for circular dependencies
   mix run debug_dag.exs
   ```

3. **Communication Issues**
   ```bash
   # Test component communication
   mix run test_communication.exs
   ```

### Logging

```elixir
# Enable debug logging
Logger.configure(level: :debug)

# Check GenServer state
:sys.get_state(Orchestrator.Scheduler)
```

## 🚀 Performance

### Optimization Tips

1. **Parallel Execution**: Independent jobs run simultaneously
2. **State Management**: Efficient MapSet operations for job tracking
3. **Memory Usage**: Immutable data structures prevent memory leaks
4. **Process Isolation**: Each component runs in separate process

### Monitoring

```elixir
# Check process info
Process.info(Orchestrator.Scheduler)

# Monitor message queue
:sys.get_status(Orchestrator.Scheduler)
```

## 🤝 Contributing

### Development Setup

```bash
# Install dependencies
mix deps.get

# Run tests
mix test

# Start development
make dev
```

### Code Style

- Follow Elixir conventions
- Use `@moduledoc` for modules
- Use `@doc` for functions
- Prefer pattern matching
- Use `with` for error handling

### Testing

- Write tests for new features
- Use descriptive test names
- Test error cases
- Maintain test coverage

## 📄 License

MIT License - see [LICENSE](../LICENSE) file for details.

---

The Orchestrator is the foundation of Loom, providing a robust, fault-tolerant engine for workflow execution. Built with Elixir/OTP, it leverages the power of the BEAM VM for concurrent, reliable job processing.
