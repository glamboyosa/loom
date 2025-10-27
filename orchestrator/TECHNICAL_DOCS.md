# 🔧 Technical Documentation - Orchestrator

This document explains how the Orchestrator works under the hood, covering Ecto parsing, DAG management, and component communication.

## 📋 Table of Contents

1. [Ecto Parsing Pipeline](#ecto-parsing-pipeline)
2. [DAG (Dependency Graph) Management](#dag-dependency-graph-management)
3. [Component Communication](#component-communication)
4. [Architecture Overview](#architecture-overview)

---

## 🔍 Ecto Parsing Pipeline

### What is Ecto?

Ecto is Elixir's database wrapper and query generator, but we're using it for **data validation** without a database. It provides:

- **Schemas**: Define data structure and validation rules
- **Changesets**: Validate and transform data safely
- **Type casting**: Convert strings to proper types

### Step-by-Step Parsing Process

#### 1. Raw YAML → Map

```yaml
# .loom.yml
name: "Test Workflow"
jobs:
  build:
    steps:
      - name: Install
        run: npm install
```

Becomes:

```elixir
%{
  "name" => "Test Workflow",
  "jobs" => %{
    "build" => %{
      "steps" => [%{"name" => "Install", "run" => "npm install"}]
    }
  }
}
```

#### 2. Ecto Schema Validation

```elixir
# Define what we expect
defmodule Orchestrator.Schemas.Workflow do
  use Ecto.Schema

  embedded_schema do
    field(:name, :string)
    field(:jobs, :map)
  end

  def changeset(workflow, attrs) do
    workflow
    |> cast(attrs, [:name, :jobs])           # Convert map to struct fields
    |> validate_required([:name, :jobs])     # Check required fields exist
    |> validate_jobs()                       # Custom validation
  end
end
```

#### 3. Changeset Creation

```elixir
# Create changeset from raw data
changeset = Workflow.changeset(%Workflow{}, yaml_data)

# This does:
# ✅ Cast "name" → workflow.name
# ✅ Cast "jobs" → workflow.jobs
# ✅ Validate name exists
# ✅ Validate jobs exist
# ✅ Check each job has "steps"
```

#### 4. Apply Changes

```elixir
# If valid, get proper struct
if changeset.valid? do
  workflow = Ecto.Changeset.apply_changes(changeset)
  # Now: workflow.name = "Test Workflow"
  #      workflow.jobs = %{"build" => %{...}}
end
```

#### 5. Convert to Job Structs

```elixir
# Transform workflow.jobs into our Job structs
Enum.map(workflow.jobs, fn {name, job_config} ->
  Job.new(
    name,                           # "build"
    job_config["steps"] || [],      # Steps array
    needs: job_config["needs"] || [] # Dependencies
  )
end)
```

### Why Use Ecto?

- **Type Safety**: Ensures data matches expected structure
- **Validation**: Clear error messages for malformed configs
- **Extensibility**: Easy to add new validation rules
- **Industry Standard**: Battle-tested in production Elixir apps

---

## 📊 DAG (Dependency Graph) Management

### What is a DAG?

A **DAG** (Directed Acyclic Graph) is a fancy way to say "a map of dependencies with no loops."

### Graph Components

#### Vertices (Nodes) = Jobs

```elixir
# Each job is a vertex in the graph
vertices = ["build", "test", "lint", "deploy"]
```

#### Edges = Dependencies

```elixir
# Edges show "who depends on whom"
# build → test    (test depends on build)
# build → lint    (lint depends on build)
# test → deploy   (deploy depends on test)
# lint → deploy   (deploy depends on lint)
```

### Visual Representation

```
    build
   /     \
  test   lint
   \     /
    deploy
```

### How Edges Are Created

```elixir
# In DAG.build/1:
Enum.reduce(jobs, graph, fn job, g ->
  Enum.reduce(job.needs, g, fn dependency, graph ->
    Graph.add_edge(graph, dependency, job.name)
    #                    ↑           ↑
    #              dependency    job that needs it
  end)
end)
```

**Example:**

- `test` has `needs: ["build"]` → creates edge `build → test`
- `deploy` has `needs: ["test", "lint"]` → creates edges `test → deploy` and `lint → deploy`

### Cycles = Bad!

A cycle means job A depends on job B, and job B depends on job A:

```
build → test → build  ❌ CYCLE!
```

**Why cycles are bad:**

- `build` can't start until `test` finishes
- `test` can't start until `build` finishes
- **Deadlock!** Nothing can ever run!

### Topological Sort = Execution Order

```elixir
# Topological sort finds a valid order:
["build", "test", "lint", "deploy"]
# This means: build first, then test and lint can run in parallel, then deploy
```

### Ready Jobs = No Incoming Edges

```elixir
# A job is "ready" when it has no unmet dependencies:
ready_jobs = ["build"]  # build has no dependencies, so it's ready
```

### DAG Operations

```elixir
# Build DAG from jobs
dag = DAG.build(jobs)

# Find ready jobs
ready = DAG.ready_jobs(dag)  # ["build"]

# Get execution order
{:ok, order} = DAG.execution_order(dag)  # ["build", "test", "lint", "deploy"]

# Check for cycles
DAG.has_cycles?(dag)  # false

# Get dependencies
DAG.dependencies(dag, "deploy")  # ["test", "lint"]

# Get dependents
DAG.dependents(dag, "build")  # ["test", "lint"]
```

---

## 🔄 Component Communication

### Architecture Overview

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐    ┌──────────────┐
│   Watcher   │───▶│  Scheduler   │───▶│   Runner    │───▶│ DockerRunner │
│             │    │              │    │             │    │              │
│ Watches     │    │ Manages DAG  │    │ Executes    │    │ Runs Docker  │
│ .loom.yml   │    │ & Job States │    │ Jobs        │    │ Containers   │
└─────────────┘    └──────────────┘    └─────────────┘    └──────────────┘
       │                   ▲                   │                   │
       │                   │                   │                   │
       └───────────────────┼───────────────────┼───────────────────┘
                           │                   │
                    Reports completion    Streams logs
```

### Communication Flow

#### 1. File Change Detection

```elixir
# Watcher detects .loom.yml change
def handle_info({:file_changed, path}, state) do
  # Tell Scheduler to reload workflow
  case Orchestrator.Scheduler.load_workflow_from_file(state.config_path) do
    {:ok, jobs} ->
      # Tell Scheduler to start executing
      Orchestrator.Scheduler.start_execution()
    {:error, reason} ->
      IO.puts("Failed to reload: #{reason}")
  end
end
```

#### 2. Workflow Loading

```elixir
# Scheduler loads and validates workflow
def handle_call({:load_workflow_from_file, file_path}, _from, state) do
  case ConfigParser.parse_file(file_path) do
    {:ok, jobs} ->
      dag = DAG.build(jobs)
      # Update state with new workflow
      new_state = %{state | jobs: Map.new(jobs, &{&1.name, &1}), dag: dag}
      {:reply, {:ok, jobs}, new_state}
  end
end
```

#### 3. Job Execution

```elixir
# Scheduler finds ready jobs and sends to Runner
def handle_cast(:start_execution, state) do
  case get_ready_jobs() do
    {:ok, ready_jobs} ->
      Enum.each(ready_jobs, fn job ->
        Orchestrator.Runner.run_job(job)  # Send to Runner
      end)
  end
end
```

#### 4. Job Execution with Docker

```elixir
# Runner executes job using DockerRunner
def handle_call({:run_job, job}, _from, state) do
  # Execute each step in Docker containers
  results = Enum.map(job.steps, fn step ->
    docker_opts = [
      workspace_path: state.workspace_path,
      image: get_job_docker_image(job),  # node:18, ubuntu:latest, etc.
      working_dir: "/workspace"
    ]

    case Orchestrator.DockerRunner.run_step(step, docker_opts) do
      {:ok, result} -> result
      {:error, reason} -> {:error, reason}
    end
  end)

  # Report completion to Scheduler
  Orchestrator.Scheduler.mark_job_completed(job.name)

  # Check for more ready jobs
  Orchestrator.Scheduler.start_execution()

  {:reply, :ok, state}
end
```

#### 5. State Updates

```elixir
# Scheduler updates job state and finds next ready jobs
def handle_call({:mark_job_completed, job_name}, _from, state) do
  new_completed = MapSet.put(state.completed_jobs, job_name)
  updated_jobs = Map.update!(state.jobs, job_name, &Job.update_state(&1, :success))

  new_state = %{state | completed_jobs: new_completed, jobs: updated_jobs}
  {:reply, :ok, new_state}
end
```

### Message Types

#### Synchronous Messages (`GenServer.call`)

- **Purpose**: Get immediate response
- **Use Cases**: Loading workflows, getting ready jobs, marking completion
- **Example**: `Orchestrator.Scheduler.get_ready_jobs()`

#### Asynchronous Messages (`GenServer.cast`)

- **Purpose**: Fire-and-forget operations
- **Use Cases**: Starting execution, file changes
- **Example**: `Orchestrator.Scheduler.start_execution()`

#### Info Messages (`handle_info`)

- **Purpose**: External events (file changes, timers)
- **Use Cases**: File system notifications
- **Example**: `{:file_changed, path}`

---

## 🏗️ Architecture Overview

### Component Responsibilities

#### Watcher

- **Purpose**: Monitor `.loom.yml` for changes
- **State**: Config file path
- **Actions**: Reload workflow when file changes

#### Scheduler

- **Purpose**: Manage workflow execution and job states
- **State**: Jobs map, DAG, completed/running jobs
- **Actions**: Load workflows, find ready jobs, track completion

#### Runner

- **Purpose**: Execute individual jobs
- **State**: Workspace path
- **Actions**: Coordinate job execution, report completion

#### DockerRunner

- **Purpose**: Execute individual steps in Docker containers
- **State**: Active Docker processes, log streams
- **Actions**: Run Docker commands, stream logs, handle timeouts

### Data Flow

```
YAML File → Parser → Job Structs → DAG → Execution Order → Job Execution
    ↑                                                              ↓
    └─────────────────── File Change Detection ←──────────────────┘
```

### State Management

Each GenServer maintains its own state:

- **Watcher**: `%{config_path: ".loom.yml"}`
- **Scheduler**: `%{jobs: %{}, dag: nil, completed_jobs: MapSet.new(), running_jobs: MapSet.new()}`
- **Runner**: `%{workspace_path: "."}`
- **DockerRunner**: `%{active_ports: %{}, timeout: 30000}`

### Error Handling

- **Validation Errors**: Ecto changesets provide clear error messages
- **Cycle Detection**: DAG validation prevents infinite loops
- **File Errors**: Graceful handling of missing or malformed files
- **Process Crashes**: OTP supervision tree restarts failed processes

---

## 🐳 Docker Integration

### Docker Image Selection

The system automatically selects Docker images based on the `runs-on` field in your YAML:

```yaml
jobs:
  build:
    runs-on: node-18 # → Uses node:18 Docker image
  test:
    runs-on: ubuntu-latest # → Uses ubuntu:latest Docker image
```

### Multi-Language Support

Loom supports **10+ programming languages and platforms** with automatic Docker image selection:

| Language    | `runs-on` Values                                                    | Docker Images                                                                                              |
| ----------- | ------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| **Node.js** | `node`, `node-16`, `node-18`, `node-20`, `node-22`                  | `node:16`, `node:18`, `node:20`, `node:22`                                                                 |
| **Python**  | `python`, `python-3.9`, `python-3.10`, `python-3.11`, `python-3.12` | `python:3.9`, `python:3.10`, `python:3.11`, `python:3.12`                                                  |
| **Go**      | `golang`, `go`, `go-1.21`, `go-1.22`, `go-1.23`                     | `golang:1.21`, `golang:1.22`, `golang:1.23`                                                                |
| **Java**    | `java`, `java-11`, `java-17`, `java-21`                             | `openjdk:11`, `openjdk:17`, `openjdk:21`                                                                   |
| **PHP**     | `php`, `php-8.1`, `php-8.2`, `php-8.3`                              | `php:8.1`, `php:8.2`, `php:8.3`                                                                            |
| **Ruby**    | `ruby`, `ruby-3.1`, `ruby-3.2`, `ruby-3.3`                          | `ruby:3.1`, `ruby:3.2`, `ruby:3.3`                                                                         |
| **Rust**    | `rust`                                                              | `rust:1.75`                                                                                                |
| **.NET**    | `dotnet`, `dotnet-6`, `dotnet-7`, `dotnet-8`                        | `mcr.microsoft.com/dotnet/sdk:6.0`, `mcr.microsoft.com/dotnet/sdk:7.0`, `mcr.microsoft.com/dotnet/sdk:8.0` |
| **Ubuntu**  | `ubuntu-latest`, `ubuntu-20.04`, `ubuntu-22.04`                     | `ubuntu:latest`, `ubuntu:20.04`, `ubuntu:22.04`                                                            |
| **Custom**  | Any Docker image name                                               | Uses as-is (e.g., `alpine:latest`, `nginx:alpine`)                                                         |

### Workspace Mounting

Loom follows the GitHub Actions pattern:

- **Workspace Mount**: Your project directory is mounted as `/workspace` in containers
- **Working Directory**: All commands run in `/workspace` context
- **File Persistence**: Files created in containers persist in your host directory
- **GitHub Actions Compatible**: Same behavior as GitHub Actions runners

### Docker Execution Flow

1. **Image Selection**: Convert `runs-on` to Docker image
2. **Container Setup**: Mount workspace, set working directory
3. **Command Execution**: Run step commands in container
4. **Log Streaming**: Capture stdout/stderr in real-time
5. **Cleanup**: Remove container after completion

### Docker Command Structure

```bash
docker run --rm \
  -v /path/to/workspace:/workspace \
  -w /workspace \
  node:18 \
  bash -c "npm install && npm run build"
```

### Log Streaming

```elixir
# DockerRunner streams logs line-by-line
defp monitor_docker_port(port, parent_pid) do
  receive do
    {^port, {:data, data}} ->
      # Send log data to parent
      send(parent_pid, {:docker_data, port, data})
      monitor_docker_port(port, parent_pid)

    {^port, {:exit_status, status}} ->
      # Send completion status
      send(parent_pid, {:docker_complete, port, status})
  end
end
```

---

## 🚀 Key Benefits

### 1. **Type Safety**

- Ecto schemas ensure data integrity
- Compile-time checks for required fields
- Clear error messages for debugging

### 2. **Dependency Management**

- Automatic cycle detection
- Optimal execution order calculation
- Parallel execution of independent jobs

### 3. **Fault Tolerance**

- GenServer supervision
- Graceful error handling
- State recovery on restart

### 4. **Extensibility**

- Easy to add new job types
- Pluggable validation rules
- Modular component design

### 5. **Observability**

- Clear logging at each step
- State inspection capabilities
- Execution flow tracking

---

This architecture provides a solid foundation for building a robust workflow execution system that can handle complex dependencies while maintaining reliability and observability.
