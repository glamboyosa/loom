#!/usr/bin/env elixir

# Test Docker execution without requiring Docker daemon

IO.puts("🐳 TESTING DOCKER EXECUTION (Simple)")
IO.puts("=" |> String.duplicate(50))

# Start DockerRunner
{:ok, docker_pid} = Orchestrator.DockerRunner.start_link()
IO.puts("✅ DockerRunner started: #{inspect(docker_pid)}")

IO.puts("\n1️⃣ Testing with a simple echo command...")

# Test a simple step that should work
test_step = %{
  "name" => "Simple Test",
  "run" => "echo 'Hello from container!'"
}

IO.puts("Running step: #{test_step["name"]}")
IO.puts("Command: #{test_step["run"]}")
IO.puts("\n--- Docker Output ---")

case Orchestrator.DockerRunner.run_step(test_step) do
  {:ok, result} ->
    IO.puts("\n--- End Docker Output ---")
    IO.puts("✅ Step completed with exit status: #{result.exit_status}")
    IO.puts("📝 Total log lines: #{length(result.logs)}")
    IO.puts("📄 Log content:")
    Enum.each(result.logs, fn log -> IO.write(log) end)

  {:error, reason} ->
    IO.puts("\n❌ Step failed: #{reason}")
end

IO.puts("\n🎉 Simple Docker test completed!")
IO.puts("Note: If Docker daemon is not running, this will fail.")
IO.puts("To test with Docker, ensure Docker Desktop or Docker daemon is running.")
