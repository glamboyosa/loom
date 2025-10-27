defmodule Orchestrator.Repo do
  @moduledoc """
  The Ecto repository for SQLite database operations.

  This repository stores:
  - Workflow execution history
  - Job logs and status
  - System metrics
  """

  use Ecto.Repo,
    otp_app: :orchestrator,
    adapter: Ecto.Adapters.SQLite3
end
