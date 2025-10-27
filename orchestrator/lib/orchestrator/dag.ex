defmodule Orchestrator.DAG do
  @moduledoc """
  DAG (Directed Acyclic Graph) for managing job dependencies and execution order
  """

  @doc """
  Builds a DAG from a list of jobs
  """
  def build(jobs) when is_list(jobs) do
    graph = Graph.new()

    # Add all jobs as vertices
    graph =
      Enum.reduce(jobs, graph, fn job, g ->
        Graph.add_vertex(g, job.name, job)
      end)

    # Add edges for dependencies (dependency -> job)
    Enum.reduce(jobs, graph, fn job, g ->
      Enum.reduce(job.needs, g, fn dependency, graph ->
        Graph.add_edge(graph, dependency, job.name)
      end)
    end)
  end

  @doc """
  Finds jobs that are ready to run (no unmet dependencies)
  """
  def ready_jobs(graph) do
    Graph.vertices(graph)
    |> Enum.filter(fn vertex ->
      # A job is ready if it has no incoming edges (no unmet dependencies)
      Graph.in_edges(graph, vertex) == []
    end)
  end

  @doc """
  Gets the execution order using topological sort
  """
  def execution_order(graph) do
    try do
      order = Graph.topsort(graph)
      {:ok, order}
    rescue
      _ -> {:error, "Circular dependency detected"}
    end
  end

  @doc """
  Checks if the DAG has any cycles
  """
  def has_cycles?(graph) do
    try do
      Graph.topsort(graph)
      false
    rescue
      _ -> true
    end
  end

  @doc """
  Gets all jobs that depend on a given job
  """
  def dependents(graph, job_name) do
    Graph.out_neighbors(graph, job_name)
  end

  @doc """
  Gets all jobs that a given job depends on
  """
  def dependencies(graph, job_name) do
    Graph.in_neighbors(graph, job_name)
  end

  @doc """
  Removes a job from the graph (when it's completed)
  """
  def remove_job(graph, job_name) do
    Graph.delete_vertex(graph, job_name)
  end

  @doc """
  Gets a job by name
  """
  def get_job(graph, job_name) do
    case Graph.vertex_labels(graph, job_name) do
      [job] -> {:ok, job}
      [] -> {:error, :not_found}
    end
  end
end
