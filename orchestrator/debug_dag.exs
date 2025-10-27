#!/usr/bin/env elixir

# Debug script to show how DAG works

IO.puts("📊 DEBUGGING DAG GRAPHS")
IO.puts("=" |> String.duplicate(50))

# Create some jobs with dependencies
jobs = [
  %Orchestrator.Job{name: "build", needs: [], steps: []},
  %Orchestrator.Job{name: "test", needs: ["build"], steps: []},
  %Orchestrator.Job{name: "lint", needs: ["build"], steps: []},
  %Orchestrator.Job{name: "deploy", needs: ["test", "lint"], steps: []}
]

IO.puts("\n1️⃣ Our jobs and their dependencies:")

Enum.each(jobs, fn job ->
  IO.puts("  #{job.name} needs: #{inspect(job.needs)}")
end)

# Build the DAG
IO.puts("\n2️⃣ Building DAG...")
dag = Orchestrator.DAG.build(jobs)

IO.puts("\n3️⃣ DAG Structure:")
IO.puts("Vertices (nodes): #{inspect(Orchestrator.DAG.ready_jobs(dag))}")

# Show edges (dependencies)
IO.puts("\n4️⃣ Edges (dependencies):")

Enum.each(jobs, fn job ->
  deps = Orchestrator.DAG.dependencies(dag, job.name)
  IO.puts("  #{job.name} depends on: #{inspect(deps)}")
end)

IO.puts("\n5️⃣ Dependents (who depends on each job):")

Enum.each(jobs, fn job ->
  dependents = Orchestrator.DAG.dependents(dag, job.name)
  IO.puts("  #{job.name} is needed by: #{inspect(dependents)}")
end)

IO.puts("\n6️⃣ Execution order (topological sort):")

case Orchestrator.DAG.execution_order(dag) do
  {:ok, order} ->
    IO.puts("  Order: #{inspect(order)}")
    IO.puts("  This means: #{Enum.join(order, " → ")}")

  {:error, reason} ->
    IO.puts("  Error: #{reason}")
end

IO.puts("\n7️⃣ Ready jobs (can run now):")
ready = Orchestrator.DAG.ready_jobs(dag)
IO.puts("  Ready: #{inspect(ready)}")
IO.puts("  These have no unmet dependencies!")

IO.puts("\n🎉 DAG debug complete!")
