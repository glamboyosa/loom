defmodule Orchestrator do
  @moduledoc """
  Loom Orchestrator - The main entry point for the workflow execution system.

  This module provides the primary interface for starting and managing the entire
  Loom system, including all components: Watcher, Scheduler, Runner, and DockerRunner.
  """

  @doc """
  Starts the entire Loom system with all components.

  This function initializes and starts all GenServers needed for the workflow
  execution system:

  - Scheduler: Manages workflow execution and job states
  - Runner: Executes individual jobs
  - DockerRunner: Runs Docker containers for job steps
  - Watcher: Monitors .loom.yml for changes

  ## Examples

      iex> Orchestrator.start()
      {:ok, [scheduler_pid, runner_pid, docker_runner_pid, watcher_pid]}

  """
  def start do
    IO.puts("🚀 Starting Loom Orchestrator...")
    IO.puts("=" |> String.duplicate(50))

    # Start all components
    IO.puts("\n1️⃣ Starting all components...")

    # Start Scheduler
    {:ok, scheduler_pid} = Orchestrator.Scheduler.start_link()
    IO.puts("✅ Scheduler started: #{inspect(scheduler_pid)}")

    # Start Runner
    {:ok, runner_pid} = Orchestrator.Runner.start_link()
    IO.puts("✅ Runner started: #{inspect(runner_pid)}")

    # Start DockerRunner
    {:ok, docker_runner_pid} = Orchestrator.DockerRunner.start_link()
    IO.puts("🐳 DockerRunner started: #{inspect(docker_runner_pid)}")

    # Start Watcher
    {:ok, watcher_pid} = Orchestrator.Watcher.start_link()
    IO.puts("🔍 Watcher: Monitoring .loom.yml")
    IO.puts("✅ Watcher started: #{inspect(watcher_pid)}")

    IO.puts("\n🎉 Loom Orchestrator is ready!")
    IO.puts("📝 To test the system, run: Orchestrator.test_workflow()")
    IO.puts("📁 To simulate file change, run: Orchestrator.Watcher.simulate_file_change()")

    {:ok, [scheduler_pid, runner_pid, docker_runner_pid, watcher_pid]}
  end

  @doc """
  Tests the workflow system by simulating a file change.

  This function triggers the complete workflow execution flow:
  1. Watcher detects file change
  2. Scheduler loads and validates workflow
  3. Runner executes jobs using DockerRunner
  4. System reports completion

  ## Examples

      iex> Orchestrator.test_workflow()
      :ok

  """
  def test_workflow do
    IO.puts("\n🧪 Testing workflow execution...")
    IO.puts("This will trigger:")
    IO.puts("  Watcher → Scheduler (reload workflow)")
    IO.puts("  Scheduler → Runner (execute jobs)")
    IO.puts("  Runner → DockerRunner (run Docker containers)")
    IO.puts("  DockerRunner → Runner (report completion)")
    IO.puts("  Runner → Scheduler (check for more jobs)")

    # Simulate file change
    Orchestrator.Watcher.simulate_file_change()

    IO.puts("\n⏳ Waiting for execution to complete...")
    # Give time for execution
    Process.sleep(2000)

    IO.puts("\n✅ Workflow test completed!")
    :ok
  end

  @doc """
  Gets the status of all system components.

  ## Examples

      iex> Orchestrator.status()
      %{
        scheduler: :running,
        runner: :running,
        docker_runner: :running,
        watcher: :running
      }

  """
  def status do
    %{
      scheduler: get_component_status(Orchestrator.Scheduler),
      runner: get_component_status(Orchestrator.Runner),
      docker_runner: get_component_status(Orchestrator.DockerRunner),
      watcher: get_component_status(Orchestrator.Watcher)
    }
  end

  @doc """
  Stops all system components.

  ## Examples

      iex> Orchestrator.stop()
      :ok

  """
  def stop do
    IO.puts("🛑 Stopping Loom Orchestrator...")

    # Stop all components
    GenServer.stop(Orchestrator.Scheduler)
    GenServer.stop(Orchestrator.Runner)
    GenServer.stop(Orchestrator.DockerRunner)
    GenServer.stop(Orchestrator.Watcher)

    IO.puts("✅ All components stopped")
    :ok
  end

  # Private functions

  defp get_component_status(module) do
    case Process.whereis(module) do
      nil -> :stopped
      _pid -> :running
    end
  end
end
