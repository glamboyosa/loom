#!/usr/bin/env elixir

# Test the communication between Watcher, Scheduler, and Runner

IO.puts("🔄 TESTING COMPONENT COMMUNICATION")
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
IO.puts("✅ Watcher started: #{inspect(watcher_pid)}")

IO.puts("\n2️⃣ Simulating file change...")
IO.puts("This should trigger:")
IO.puts("  Watcher → Scheduler (reload workflow)")
IO.puts("  Scheduler → Runner (execute jobs)")
IO.puts("  Runner → Scheduler (report completion)")
IO.puts("  Scheduler → Runner (execute next jobs)")

# Simulate file change
Orchestrator.Watcher.simulate_file_change()

IO.puts("\n3️⃣ Waiting for execution to complete...")
# Wait for all jobs to complete
Process.sleep(5000)

IO.puts("\n🎉 Communication test completed!")
IO.puts("Check the output above to see the communication flow!")
