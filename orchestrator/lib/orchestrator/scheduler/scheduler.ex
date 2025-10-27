defmodule Orchestrator.Scheduler do
  @moduledoc """
  Scheduler - parses .loom.yml and builds a DAG (jobs + dependencies).
  Maintains job states: pending, running, success, failed
  """

  use GenServer

  alias Orchestrator.ConfigParser
  alias Orchestrator.DAG
  alias Orchestrator.Job

  # Client API
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def load_workflow_from_file(file_path) do
    GenServer.call(__MODULE__, {:load_workflow_from_file, file_path})
  end

  def load_workflow_from_yaml(yaml_content) do
    GenServer.call(__MODULE__, {:load_workflow_from_yaml, yaml_content})
  end

  def get_ready_jobs do
    GenServer.call(__MODULE__, :get_ready_jobs)
  end

  def mark_job_completed(job_name) do
    GenServer.call(__MODULE__, {:mark_job_completed, job_name})
  end

  def start_execution do
    GenServer.cast(__MODULE__, :start_execution)
  end

  def get_workflows do
    GenServer.call(__MODULE__, :get_workflows)
  end

  def get_job_status(job_name) do
    GenServer.call(__MODULE__, {:get_job_status, job_name})
  end

  # Server callbacks
  @impl true
  def init(_opts) do
    {:ok,
     %{
       jobs: %{},
       dag: nil,
       completed_jobs: MapSet.new(),
       running_jobs: MapSet.new()
     }}
  end

  @impl true
  def handle_call({:load_workflow_from_file, file_path}, _from, state) do
    case ConfigParser.parse_file(file_path) do
      {:ok, jobs} ->
        dag = DAG.build(jobs)

        if DAG.has_cycles?(dag) do
          {:reply, {:error, "Circular dependencies detected"}, state}
        else
          new_state = %{
            state
            | jobs: Map.new(jobs, &{&1.name, &1}),
              dag: dag,
              completed_jobs: MapSet.new(),
              running_jobs: MapSet.new()
          }

          {:reply, {:ok, jobs}, new_state}
        end

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:load_workflow_from_yaml, yaml_content}, _from, state) do
    case ConfigParser.parse_yaml(yaml_content) do
      {:ok, jobs} ->
        dag = DAG.build(jobs)

        if DAG.has_cycles?(dag) do
          {:reply, {:error, "Circular dependencies detected"}, state}
        else
          new_state = %{
            state
            | jobs: Map.new(jobs, &{&1.name, &1}),
              dag: dag,
              completed_jobs: MapSet.new(),
              running_jobs: MapSet.new()
          }

          {:reply, {:ok, jobs}, new_state}
        end

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call(:get_ready_jobs, _from, state) do
    if state.dag do
      ready_job_names = DAG.ready_jobs(state.dag)
      # Filter out already completed and running jobs
      available_jobs =
        ready_job_names
        |> Enum.reject(&(&1 in state.completed_jobs))
        |> Enum.reject(&(&1 in state.running_jobs))

      ready_jobs = Enum.map(available_jobs, &state.jobs[&1])
      {:reply, {:ok, ready_jobs}, state}
    else
      {:reply, {:error, "No workflow loaded"}, state}
    end
  end

  @impl true
  def handle_call({:mark_job_completed, job_name}, _from, state) do
    new_completed = MapSet.put(state.completed_jobs, job_name)
    new_running = MapSet.delete(state.running_jobs, job_name)

    # Update job state
    updated_jobs =
      Map.update!(state.jobs, job_name, fn job ->
        Job.update_state(job, :success)
      end)

    new_state = %{
      state
      | completed_jobs: new_completed,
        running_jobs: new_running,
        jobs: updated_jobs
    }

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:get_workflows, _from, state) do
    workflows = if state.jobs do
      # Convert jobs to workflow format
      [%{
        name: "Current Workflow",
        on: ["push", "pull_request"],
        jobs: Map.new(state.jobs, fn {name, job} -> {name, job} end)
      }]
    else
      []
    end

    {:reply, {:ok, workflows}, state}
  end

  @impl true
  def handle_call({:get_job_status, job_name}, _from, state) do
    case Map.get(state.jobs, job_name) do
      nil ->
        {:reply, {:error, "Job not found"}, state}
      job ->
        {:reply, {:ok, %{name: job.name, state: job.state, steps: job.steps}}, state}
    end
  end

  @impl true
  def handle_cast(:start_execution, state) do
    IO.puts("🚀 Scheduler: Starting execution...")

    if state.dag do
      # Get ready jobs directly from state (avoid self-call)
      ready_job_names = DAG.ready_jobs(state.dag)
      # Filter out already completed and running jobs
      available_jobs =
        ready_job_names
        |> Enum.reject(&(&1 in state.completed_jobs))
        |> Enum.reject(&(&1 in state.running_jobs))

      ready_jobs = Enum.map(available_jobs, &state.jobs[&1])

      if length(ready_jobs) > 0 do
        IO.puts("📋 Scheduler: Found #{length(ready_jobs)} ready jobs")
        # Send jobs to Runner
        Enum.each(ready_jobs, fn job ->
          IO.puts("🏃 Scheduler: Sending job '#{job.name}' to Runner")
          Orchestrator.Runner.run_job(job)
        end)
      else
        IO.puts("✅ Scheduler: No ready jobs, workflow complete!")
      end
    else
      IO.puts("❌ Scheduler: No workflow loaded")
    end

    {:noreply, state}
  end

end
