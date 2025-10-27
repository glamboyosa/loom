defmodule Orchestrator.Job do
  @moduledoc """
  Job struct representing a single job in the workflow.
  """

  @enforce_keys [:name, :steps]
  defstruct name: nil,
            needs: [],
            steps: [],
            state: :pending,
            runs_on: "ubuntu-latest"

  @type t :: %__MODULE__{
          name: String.t(),
          needs: list(String.t()),
          steps: list(map()),
          state: atom(),
          runs_on: String.t()
        }

  @doc """
  Creates a new job with the given name and steps.
  """
  def new(name, steps, opts \\ []) do
    %__MODULE__{
      name: name,
      steps: steps,
      needs: opts[:needs] || [],
      state: :pending,
      runs_on: opts[:runs_on] || "ubuntu-latest"
    }
  end

  @doc """
  Updates the job state.
  """
  def update_state(job, new_state) do
    %{job | state: new_state}
  end

  @doc """
  Checks if a job is ready to run (all dependencies satisfied).
  """
  def ready?(job, completed_jobs \\ []) do
    Enum.all?(job.needs, &(&1 in completed_jobs))
  end
end
