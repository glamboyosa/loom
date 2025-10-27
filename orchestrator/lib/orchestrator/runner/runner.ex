defmodule Orchestrator.Runner do
  @moduledoc """
  Runner - executes jobs by starting Docker containers.
  For each ready job:
  - Starts a Docker container with mounted workspace
  - Runs the step commands
  - Streams stdout and stderr line-by-line to a log channel
  """

  use GenServer

  # Client API
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def run_job(job) do
    GenServer.call(__MODULE__, {:run_job, job})
  end

  # Server callbacks
  @impl true
  def init(opts) do
    {:ok, %{workspace_path: opts[:workspace_path] || "."}}
  end

  @impl true
  def handle_call({:run_job, job}, _from, state) do
    IO.puts("🏃 Runner: Starting job '#{job.name}'")

    # Execute each step in the job
    results =
      Enum.map(job.steps, fn step ->
        IO.puts("📋 Runner: Executing step '#{step["name"]}'")

        # Build Docker options from job configuration
        docker_opts = [
          workspace_path: state.workspace_path,
          image: get_job_docker_image(job),
          working_dir: "/workspace"
        ]

        case Orchestrator.DockerRunner.run_step(step, docker_opts) do
          {:ok, result} ->
            IO.puts("✅ Runner: Step '#{step["name"]}' completed (exit: #{result.exit_status})")
            result

          {:error, reason} ->
            IO.puts("❌ Runner: Step '#{step["name"]}' failed: #{reason}")
            {:error, reason}
        end
      end)

    # Check if any step failed
    failed_steps = Enum.filter(results, &match?({:error, _}, &1))

    if length(failed_steps) > 0 do
      IO.puts("❌ Runner: Job '#{job.name}' failed due to step failures")
      # TODO: Handle job failure
    else
      IO.puts("✅ Runner: Job '#{job.name}' completed successfully")
    end

    # Report back to Scheduler
    Orchestrator.Scheduler.mark_job_completed(job.name)

    # Check for more ready jobs
    Process.sleep(100)
    Orchestrator.Scheduler.start_execution()

    {:reply, :ok, state}
  end

  # Private functions

  defp get_job_docker_image(job) do
    # Use the Docker image specified in the job's runs_on field
    # Convert GitHub Actions style to Docker image names
    case job.runs_on do
      # Ubuntu variants
      "ubuntu-latest" -> "ubuntu:latest"
      "ubuntu-20.04" -> "ubuntu:20.04"
      "ubuntu-22.04" -> "ubuntu:22.04"
      # Node.js variants
      "node" -> "node:18"
      "node-16" -> "node:16"
      "node-18" -> "node:18"
      "node-20" -> "node:20"
      "node-22" -> "node:22"
      # Python variants
      "python" -> "python:3.11"
      "python-3.9" -> "python:3.9"
      "python-3.10" -> "python:3.10"
      "python-3.11" -> "python:3.11"
      "python-3.12" -> "python:3.12"
      # Go variants
      "golang" -> "golang:1.22"
      "go" -> "golang:1.22"
      "go-1.21" -> "golang:1.21"
      "go-1.22" -> "golang:1.22"
      "go-1.23" -> "golang:1.23"
      # Java variants
      "java" -> "openjdk:17"
      "java-11" -> "openjdk:11"
      "java-17" -> "openjdk:17"
      "java-21" -> "openjdk:21"
      # PHP variants
      "php" -> "php:8.2"
      "php-8.1" -> "php:8.1"
      "php-8.2" -> "php:8.2"
      "php-8.3" -> "php:8.3"
      # Ruby variants
      "ruby" -> "ruby:3.2"
      "ruby-3.1" -> "ruby:3.1"
      "ruby-3.2" -> "ruby:3.2"
      "ruby-3.3" -> "ruby:3.3"
      # Rust
      "rust" -> "rust:1.75"
      # .NET
      "dotnet" -> "mcr.microsoft.com/dotnet/sdk:8.0"
      "dotnet-6" -> "mcr.microsoft.com/dotnet/sdk:6.0"
      "dotnet-7" -> "mcr.microsoft.com/dotnet/sdk:7.0"
      "dotnet-8" -> "mcr.microsoft.com/dotnet/sdk:8.0"
      # Use as-is if it's a custom image (e.g., "alpine:latest", "nginx:alpine")
      custom_image when is_binary(custom_image) -> custom_image
      _ -> "ubuntu:latest"
    end
  end
end
