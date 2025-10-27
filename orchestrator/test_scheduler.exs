#!/usr/bin/env elixir

# Test the Scheduler GenServer
IO.puts("🧪 Testing Scheduler GenServer")
IO.puts("=" |> String.duplicate(50))

# Start the scheduler
IO.puts("\n1️⃣ Starting Scheduler...")
{:ok, pid} = Orchestrator.Scheduler.start_link()
IO.puts("✅ Scheduler started with PID: #{inspect(pid)}")

# Load workflow from file
IO.puts("\n2️⃣ Loading workflow from file...")

case Orchestrator.Scheduler.load_workflow_from_file("test.loom.yml") do
  {:ok, jobs} ->
    IO.puts("✅ Workflow loaded with #{length(jobs)} jobs:")

    Enum.each(jobs, fn job ->
      IO.puts("   - #{job.name} (needs: #{inspect(job.needs)})")
    end)

    # Get ready jobs
    IO.puts("\n3️⃣ Getting ready jobs...")

    case Orchestrator.Scheduler.get_ready_jobs() do
      {:ok, ready_jobs} ->
        IO.puts("✅ Ready jobs: #{length(ready_jobs)}")

        Enum.each(ready_jobs, fn job ->
          IO.puts("   - #{job.name}")
        end)

        # Mark a job as completed
        if length(ready_jobs) > 0 do
          first_job = hd(ready_jobs)
          IO.puts("\n4️⃣ Marking '#{first_job.name}' as completed...")
          Orchestrator.Scheduler.mark_job_completed(first_job.name)
          IO.puts("✅ Job marked as completed")

          # Check ready jobs again
          IO.puts("\n5️⃣ Getting ready jobs after completion...")

          case Orchestrator.Scheduler.get_ready_jobs() do
            {:ok, new_ready_jobs} ->
              IO.puts("✅ New ready jobs: #{length(new_ready_jobs)}")

              Enum.each(new_ready_jobs, fn job ->
                IO.puts("   - #{job.name}")
              end)

            {:error, reason} ->
              IO.puts("❌ Error: #{reason}")
          end
        end

      {:error, reason} ->
        IO.puts("❌ Error getting ready jobs: #{reason}")
    end

  {:error, reason} ->
    IO.puts("❌ Failed to load workflow: #{reason}")
end

IO.puts("\n🎉 Scheduler test completed!")
