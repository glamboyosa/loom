defmodule Orchestrator.Watcher do
  @moduledoc """
  Config Watcher - watches .loom.yml with fsnotify.
  When modified, reloads the workflow.
  """

  use GenServer

  # Client API
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # Server callbacks
  @impl true
  def init(opts) do
    config_path = opts[:config_path] || "test-multi-language.loom.yml"
    IO.puts("🔍 Watcher: Monitoring #{config_path}")

    # Start file watcher
    start_file_watcher(config_path)

    {:ok, %{config_path: config_path}}
  end

  @impl true
  def handle_info({:file_changed, path}, state) do
    IO.puts("📁 Watcher: Config file changed: #{path}")

    # Tell Scheduler to reload workflow
    case Orchestrator.Scheduler.load_workflow_from_file(state.config_path) do
      {:ok, jobs} ->
        IO.puts("✅ Watcher: Workflow reloaded with #{length(jobs)} jobs")
        # Tell Scheduler to start executing
        Orchestrator.Scheduler.start_execution()

      {:error, reason} ->
        IO.puts("❌ Watcher: Failed to reload workflow: #{reason}")
    end

    {:noreply, state}
  end

  # Simulate file change for testing
  def simulate_file_change do
    GenServer.cast(__MODULE__, :simulate_change)
  end

  @impl true
  def handle_cast(:simulate_change, state) do
    send(self(), {:file_changed, state.config_path})
    {:noreply, state}
  end

  # Private functions

  defp start_file_watcher(config_path) do
    # Start a process to watch the file
    Task.start(fn ->
      watch_file_loop(config_path)
    end)
  end

  defp watch_file_loop(config_path) do
    if File.exists?(config_path) do
      # Get initial modification time
      case File.stat(config_path) do
        {:ok, stat} ->
          last_modified = stat.mtime
          watch_file_loop(config_path, last_modified)

        {:error, _} ->
          IO.puts("❌ Watcher: Cannot access #{config_path}")
      end
    else
      IO.puts("❌ Watcher: File #{config_path} does not exist")
      # Check again in 5 seconds
      Process.sleep(5000)
      watch_file_loop(config_path)
    end
  end

  defp watch_file_loop(config_path, last_modified) do
    # Check every second
    Process.sleep(1000)

    case File.stat(config_path) do
      {:ok, stat} ->
        if stat.mtime > last_modified do
          IO.puts("📁 Watcher: File #{config_path} changed!")
          send(__MODULE__, {:file_changed, config_path})
          watch_file_loop(config_path, stat.mtime)
        else
          watch_file_loop(config_path, last_modified)
        end

      {:error, _} ->
        IO.puts("❌ Watcher: Lost access to #{config_path}")
        Process.sleep(5000)
        watch_file_loop(config_path, last_modified)
    end
  end
end
