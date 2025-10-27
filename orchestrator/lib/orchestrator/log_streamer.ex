defmodule Orchestrator.LogStreamer do
  @moduledoc """
  LogStreamer - handles real-time log streaming to WebSocket clients.

  This module will be used to stream Docker execution logs to web dashboard clients
  via WebSocket connections.
  """

  use GenServer

  # Client API
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def subscribe_to_job(job_name) do
    GenServer.call(__MODULE__, {:subscribe, job_name})
  end

  def stream_log(job_name, step_name, log_data) do
    GenServer.cast(__MODULE__, {:stream_log, job_name, step_name, log_data})
  end

  def get_job_logs(job_name) do
    GenServer.call(__MODULE__, {:get_logs, job_name})
  end

  # Server callbacks
  @impl true
  def init(_opts) do
    {:ok,
     %{
       # job_name => [websocket_pids]
       subscribers: %{},
       # job_name => [log_entries]
       logs: %{}
     }}
  end

  @impl true
  def handle_call({:subscribe, job_name}, {from, _ref}, state) do
    # Add subscriber to job
    current_subscribers = Map.get(state.subscribers, job_name, [])
    new_subscribers = [from | current_subscribers]

    new_state = %{
      state
      | subscribers: Map.put(state.subscribers, job_name, new_subscribers)
    }

    # Send existing logs to new subscriber
    existing_logs = Map.get(state.logs, job_name, [])

    Enum.each(existing_logs, fn log_entry ->
      send(from, {:log_data, log_entry})
    end)

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:get_logs, job_name}, _from, state) do
    logs = Map.get(state.logs, job_name, [])
    {:reply, {:ok, logs}, state}
  end

  @impl true
  def handle_cast({:stream_log, job_name, step_name, log_data}, state) do
    # Create log entry
    log_entry = %{
      timestamp: DateTime.utc_now(),
      job_name: job_name,
      step_name: step_name,
      data: log_data
    }

    # Store log
    current_logs = Map.get(state.logs, job_name, [])
    new_logs = current_logs ++ [log_entry]

    # Broadcast to subscribers
    subscribers = Map.get(state.subscribers, job_name, [])

    Enum.each(subscribers, fn subscriber_pid ->
      send(subscriber_pid, {:log_data, log_entry})
    end)

    new_state = %{
      state
      | logs: Map.put(state.logs, job_name, new_logs)
    }

    {:noreply, new_state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    # Remove dead subscribers
    new_subscribers =
      state.subscribers
      |> Enum.map(fn {job_name, subscribers} ->
        alive_subscribers = Enum.reject(subscribers, &(&1 == pid))
        {job_name, alive_subscribers}
      end)
      |> Enum.into(%{})

    {:noreply, %{state | subscribers: new_subscribers}}
  end
end
