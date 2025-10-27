import { query, command } from '$app/server';
import { z } from 'zod';

// Types for our workflow system
export interface Job {
	name: string;
	needs: string[];
	steps: Array<{
		name: string;
		run: string;
	}>;
	state: 'pending' | 'running' | 'success' | 'failed';
	runs_on: string;
}

export interface Workflow {
	name: string;
	on: string[];
	jobs: Record<string, Job>;
}

export interface LogEntry {
	timestamp: string;
	level: 'info' | 'error' | 'warn' | 'debug';
	message: string;
	job_name: string;
	step_name: string;
}

// Validation schemas
const JobSchema = z.object({
	name: z.string(),
	needs: z.array(z.string()),
	steps: z.array(z.object({
		name: z.string(),
		run: z.string()
	})),
	state: z.enum(['pending', 'running', 'success', 'failed']),
	runs_on: z.string()
});

const WorkflowSchema = z.object({
	name: z.string(),
	on: z.array(z.string()),
	jobs: z.record(z.string(), JobSchema)
});

// Remote functions to communicate with Elixir orchestrator

/**
 * Get the current system status
 */
export const getSystemStatus = query(async () => {
	// Make HTTP call to the Elixir orchestrator
	const response = await fetch('http://localhost:4000/api/status');
	if (!response.ok) {
		throw new Error(`HTTP error! status: ${response.status}`);
	}
	return response.json();
});

/**
 * Get all workflows and their current state
 */
export const getWorkflows = query(async () => {
	// Fetch from the Elixir orchestrator
	const response = await fetch('http://localhost:4000/api/workflows');
	if (!response.ok) {
		throw new Error(`HTTP error! status: ${response.status}`);
	}
	return response.json();
});

/**
 * Get logs for a specific job
 */
export const getJobLogs = query(
	z.object({ job_name: z.string() }),
	async ({ job_name }) => {
		// Fetch logs from the Elixir orchestrator
		const response = await fetch(`http://localhost:4000/api/jobs/${job_name}/logs`);
		if (!response.ok) {
			throw new Error(`HTTP error! status: ${response.status}`);
		}
		return response.json();
	}
);

/**
 * Start workflow execution
 */
export const startWorkflow = command(
	z.object({ workflow_name: z.string() }),
	async ({ workflow_name }) => {
		// Trigger the Elixir orchestrator to start execution
		const response = await fetch(`http://localhost:4000/api/workflows/${workflow_name}/start`, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' }
		});
		
		if (!response.ok) {
			throw new Error(`HTTP error! status: ${response.status}`);
		}
		
		return response.json();
	}
);

/**
 * Stop workflow execution
 */
export const stopWorkflow = command(
	z.object({ workflow_name: z.string() }),
	async ({ workflow_name }) => {
		// Stop the Elixir orchestrator execution
		const response = await fetch(`http://localhost:4000/api/workflows/${workflow_name}/stop`, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' }
		});
		
		if (!response.ok) {
			throw new Error(`HTTP error! status: ${response.status}`);
		}
		
		return response.json();
	}
);

/**
 * Reload workflow from file
 */
export const reloadWorkflow = command(
	z.object({ file_path: z.string() }),
	async ({ file_path }) => {
		// Trigger the Elixir orchestrator to reload the workflow
		const response = await fetch('http://localhost:4000/api/workflows/reload', {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ file_path })
		});
		
		if (!response.ok) {
			throw new Error(`HTTP error! status: ${response.status}`);
		}
		
		return response.json();
	}
);
