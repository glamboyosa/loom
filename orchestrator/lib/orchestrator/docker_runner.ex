defmodule Orchestrator.DockerRunner do
  @moduledoc """
  DockerRunner - executes individual steps in Docker containers with real-time log streaming.

  Features:
  - Real-time log streaming (no buffering)
  - WebSocket streaming for web UI
  - Container isolation
  - Volume mounting for workspace access
  """

  use GenServer

  # Client API
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def run_step(step, opts \\ []) do
    GenServer.call(__MODULE__, {:run_step, step, opts})
  end

  # Server callbacks
  @impl true
  def init(opts) do
    workspace_path = opts[:workspace_path] || File.cwd!()
    {:ok, %{workspace_path: workspace_path, active_ports: %{}}}
  end

  @impl true
  def handle_call({:run_step, step, opts}, from, state) do
    IO.puts("🐳 DockerRunner: Starting step '#{step["name"]}'")

    # Build Docker command
    docker_args = build_docker_args(step, state.workspace_path, opts)

    # Start Docker container
    port =
      Port.open(
        {:spawn_executable, System.find_executable("docker")},
        [:binary, :exit_status, args: docker_args]
      )

    # Track the port and caller
    new_active_ports =
      Map.put(state.active_ports, port, %{
        from: from,
        step: step,
        logs: []
      })

    # Start monitoring the port
    send(self(), {:monitor_port, port})

    {:noreply, %{state | active_ports: new_active_ports}}
  end

  @impl true
  def handle_info({:monitor_port, port}, state) do
    # Start the monitoring loop
    Task.start(fn -> monitor_docker_port(port, self()) end)
    {:noreply, state}
  end

  @impl true
  def handle_info({:docker_data, port, data}, state) do
    case Map.get(state.active_ports, port) do
      nil ->
        {:noreply, state}

      port_info ->
        # Stream logs in real-time
        IO.write(data)

        # Store logs for later retrieval
        updated_logs = port_info.logs ++ [data]
        updated_port_info = %{port_info | logs: updated_logs}

        # TODO: Stream to WebSocket clients
        stream_to_websocket(port_info.step, data)

        new_active_ports = Map.put(state.active_ports, port, updated_port_info)
        {:noreply, %{state | active_ports: new_active_ports}}
    end
  end

  @impl true
  def handle_info({:docker_exit, port, exit_status}, state) do
    case Map.get(state.active_ports, port) do
      nil ->
        {:noreply, state}

      port_info ->
        IO.puts(
          "\n🐳 DockerRunner: Step '#{port_info.step["name"]}' exited with status #{exit_status}"
        )

        # Reply to the caller
        GenServer.reply(
          port_info.from,
          {:ok,
           %{
             step: port_info.step,
             exit_status: exit_status,
             logs: port_info.logs
           }}
        )

        # Clean up
        new_active_ports = Map.delete(state.active_ports, port)
        {:noreply, %{state | active_ports: new_active_ports}}
    end
  end

  # Handle direct port messages
  @impl true
  def handle_info({port, {:data, data}}, state) do
    case Map.get(state.active_ports, port) do
      nil ->
        {:noreply, state}

      port_info ->
        # Stream logs in real-time
        IO.write(data)

        # Store logs for later retrieval
        updated_logs = port_info.logs ++ [data]
        updated_port_info = %{port_info | logs: updated_logs}

        # TODO: Stream to WebSocket clients
        stream_to_websocket(port_info.step, data)

        new_active_ports = Map.put(state.active_ports, port, updated_port_info)
        {:noreply, %{state | active_ports: new_active_ports}}
    end
  end

  @impl true
  def handle_info({port, {:exit_status, exit_status}}, state) do
    case Map.get(state.active_ports, port) do
      nil ->
        {:noreply, state}

      port_info ->
        IO.puts(
          "\n🐳 DockerRunner: Step '#{port_info.step["name"]}' exited with status #{exit_status}"
        )

        # Reply to the caller
        GenServer.reply(
          port_info.from,
          {:ok,
           %{
             step: port_info.step,
             exit_status: exit_status,
             logs: port_info.logs
           }}
        )

        # Clean up
        new_active_ports = Map.delete(state.active_ports, port)
        {:noreply, %{state | active_ports: new_active_ports}}
    end
  end

  # Private functions

  defp build_docker_args(step, workspace_path, opts) do
    # Get image from job config or use default
    image = opts[:image] || "ubuntu:latest"
    working_dir = opts[:working_dir] || "/workspace"

    # Build Docker command
    base_args = [
      "run",
      "--rm",
      "-v",
      "#{workspace_path}:#{working_dir}",
      "-w",
      working_dir
    ]

    # Add environment variables if specified
    env_args =
      case opts[:env] do
        nil -> []
        env_vars -> Enum.flat_map(env_vars, fn {key, value} -> ["-e", "#{key}=#{value}"] end)
      end

    # Add the image and command
    command_args = [image, "bash", "-c", step["run"]]

    base_args ++ env_args ++ command_args
  end

  defp monitor_docker_port(port, parent_pid) do
    receive do
      {^port, {:data, data}} ->
        send(parent_pid, {:docker_data, port, data})
        monitor_docker_port(port, parent_pid)

      {^port, {:exit_status, status}} ->
        send(parent_pid, {:docker_exit, port, status})
    end
  end

  defp stream_to_websocket(step, data) do
    # Print to console
    IO.write(data)

    # Broadcast to Phoenix channel
    log_entry = %{
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      level: "info",
      message: data,
      job_name: step["job_name"] || "unknown",
      step_name: step["name"] || "unknown",
      workflow_name: "Current Workflow"
    }

    # Broadcast to Phoenix channel
    OrchestratorWeb.LogChannel.broadcast_log(log_entry)
  end
end
