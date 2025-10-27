#!/usr/bin/env elixir

# Test Docker execution with real-time logging

IO.puts("🐳 TESTING DOCKER EXECUTION")
IO.puts("=" |> String.duplicate(50))

# Start all components
IO.puts("\n1️⃣ Starting all components...")

# Start DockerRunner
{:ok, docker_pid} = Orchestrator.DockerRunner.start_link()
IO.puts("✅ DockerRunner started: #{inspect(docker_pid)}")

# Start Scheduler
{:ok, scheduler_pid} = Orchestrator.Scheduler.start_link()
IO.puts("✅ Scheduler started: #{inspect(scheduler_pid)}")

# Start Runner
{:ok, runner_pid} = Orchestrator.Runner.start_link()
IO.puts("✅ Runner started: #{inspect(runner_pid)}")

# Start Watcher
{:ok, watcher_pid} = Orchestrator.Watcher.start_link()
IO.puts("✅ Watcher started: #{inspect(watcher_pid)}")

IO.puts("\n2️⃣ Testing Docker step execution...")

# Test a simple Docker step
test_step = %{
  "name" => "Hello World",
  "run" =>
    "echo 'Hello from Docker!' && echo 'Current directory:' && pwd && echo 'Files:' && ls -la"
}

IO.puts("Running step: #{test_step["name"]}")
IO.puts("Command: #{test_step["run"]}")
IO.puts("\n--- Docker Output ---")

case Orchestrator.DockerRunner.run_step(test_step) do
  {:ok, result} ->
    IO.puts("\n--- End Docker Output ---")
    IO.puts("✅ Step completed with exit status: #{result.exit_status}")
    IO.puts("📝 Total log lines: #{length(result.logs)}")

  {:error, reason} ->
    IO.puts("\n❌ Step failed: #{reason}")
end

IO.puts("\n3️⃣ Testing full workflow with Docker...")
IO.puts("This will execute the build job from test.loom.yml using Docker")

# Simulate file change to trigger workflow
Orchestrator.Watcher.simulate_file_change()

IO.puts("\n4️⃣ Waiting for workflow execution...")
# Wait for Docker execution
Process.sleep(10000)

IO.puts("\n🎉 Docker test completed!")
IO.puts("Check the output above to see real-time Docker execution!")
