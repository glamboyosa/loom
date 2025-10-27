#!/usr/bin/env elixir

# Debug script to show exactly what Ecto parsing does

IO.puts("🔍 DEBUGGING ECTO PARSING")
IO.puts("=" |> String.duplicate(50))

# Step 1: Raw YAML parsing
IO.puts("\n1️⃣ Raw YAML parsing with YamlElixir...")

yaml_content = """
name: "Test Workflow"
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Install dependencies
        run: npm install
      - name: Build
        run: npm run build
  test:
    needs: [build]
    runs-on: ubuntu-latest
    steps:
      - name: Run tests
        run: npm test
"""

{:ok, raw_yaml} = YamlElixir.read_from_string(yaml_content)
IO.puts("Raw YAML data:")
IO.inspect(raw_yaml, pretty: true, limit: :infinity)

# Step 2: Ecto changeset creation
IO.puts("\n2️⃣ Creating Ecto changeset...")
workflow = %Orchestrator.Schemas.Workflow{}
changeset = Orchestrator.Schemas.Workflow.changeset(workflow, raw_yaml)
IO.puts("Changeset valid?: #{changeset.valid?}")
IO.puts("Changeset errors: #{inspect(changeset.errors)}")
IO.puts("Changeset changes: #{inspect(changeset.changes)}")

# Step 3: Apply changes to get workflow struct
IO.puts("\n3️⃣ Applying changes to get workflow struct...")

if changeset.valid? do
  workflow_struct = Ecto.Changeset.apply_changes(changeset)
  IO.puts("Workflow struct:")
  IO.inspect(workflow_struct, pretty: true)

  IO.puts("\n4️⃣ Accessing workflow.jobs...")
  IO.puts("workflow.jobs type: #{inspect(workflow_struct.jobs)}")
  IO.puts("workflow.jobs keys: #{inspect(Map.keys(workflow_struct.jobs))}")

  # Show each job
  Enum.each(workflow_struct.jobs, fn {name, job_config} ->
    IO.puts("\nJob '#{name}':")
    IO.inspect(job_config, pretty: true)
  end)
end

IO.puts("\n🎉 Parsing debug complete!")
