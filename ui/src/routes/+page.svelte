<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { getSystemStatus, getWorkflows, startWorkflow, stopWorkflow } from '$lib/orchestrator.remote.js';
	import { connectWebSocket, disconnectWebSocket, wsConnected, wsError } from '$lib/stores/websocket.js';
	import type { Workflow, Job } from '$lib/orchestrator.remote.js';

	// Load data using remote functions
	const systemStatus = await getSystemStatus();
	const workflows = await getWorkflows();

	// Reactive state
	let selectedWorkflow = $state<Workflow | null>(workflows[0] || null);
	let selectedJob = $state<Job | null>(null);

	onMount(() => {
		// Connect to WebSocket for real-time logs
		connectWebSocket();
	});

	onDestroy(() => {
		// Clean up WebSocket connection
		disconnectWebSocket();
	});

	// Workflow actions
	async function handleStartWorkflow() {
		if (selectedWorkflow) {
			await startWorkflow({ workflow_name: selectedWorkflow.name });
		}
	}

	async function handleStopWorkflow() {
		if (selectedWorkflow) {
			await stopWorkflow({ workflow_name: selectedWorkflow.name });
		}
	}

	function selectJob(job: Job) {
		selectedJob = job;
	}

	// Get job status color
	function getJobStatusColor(state: Job['state']) {
		switch (state) {
			case 'success': return 'text-green-600 bg-green-100';
			case 'running': return 'text-blue-600 bg-blue-100';
			case 'failed': return 'text-red-600 bg-red-100';
			case 'pending': return 'text-gray-600 bg-gray-100';
			default: return 'text-gray-600 bg-gray-100';
		}
	}
</script>

<svelte:head>
	<title>Loom - Self-hosted Actions Runner</title>
</svelte:head>

<div class="min-h-screen bg-gray-50">
	<!-- Header -->
	<header class="bg-white shadow-sm border-b">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="flex justify-between items-center py-4">
				<div class="flex items-center">
					<h1 class="text-2xl font-bold text-gray-900">🧵 Loom</h1>
					<span class="ml-2 text-sm text-gray-500">Self-hosted Actions Runner</span>
				</div>
				
				<!-- System Status -->
				<div class="flex items-center space-x-4">
					<div class="flex items-center space-x-2">
						<div class="w-2 h-2 bg-green-500 rounded-full"></div>
						<span class="text-sm text-gray-600">System Online</span>
					</div>
					
					<!-- WebSocket Status -->
					{#if $wsConnected}
						<div class="flex items-center space-x-2">
							<div class="w-2 h-2 bg-green-500 rounded-full"></div>
							<span class="text-sm text-gray-600">Live Logs</span>
						</div>
					{:else}
						<div class="flex items-center space-x-2">
							<div class="w-2 h-2 bg-red-500 rounded-full"></div>
							<span class="text-sm text-red-600">Logs Offline</span>
						</div>
					{/if}
				</div>
			</div>
		</div>
	</header>

	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
		<!-- Workflow Selection -->
		<div class="mb-8">
			<div class="flex items-center justify-between mb-4">
				<h2 class="text-xl font-semibold text-gray-900">Workflows</h2>
				<div class="flex space-x-2">
					<button
						onclick={handleStartWorkflow}
						disabled={!selectedWorkflow}
						class="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed"
					>
						▶️ Start
					</button>
					<button
						onclick={handleStopWorkflow}
						disabled={!selectedWorkflow}
						class="px-4 py-2 bg-red-600 text-white rounded-md hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed"
					>
						⏹️ Stop
					</button>
				</div>
			</div>

			{#if workflows.length > 0}
				<div class="grid gap-4">
					{#each workflows as workflow}
						<div class="bg-white rounded-lg shadow p-6">
							<div class="flex items-center justify-between mb-4">
								<h3 class="text-lg font-medium text-gray-900">{workflow.name}</h3>
								<span class="text-sm text-gray-500">Triggers: {workflow.on.join(', ')}</span>
							</div>

							<!-- Jobs Grid -->
							<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
								{#each Object.values(workflow.jobs) as job}
								<button
									onclick={() => selectJob(job)}
									class="p-4 border rounded-lg hover:bg-gray-50 transition-colors {selectedJob?.name === job.name ? 'ring-2 ring-blue-500' : ''}"
								>
										<div class="flex items-center justify-between mb-2">
											<h4 class="font-medium text-gray-900">{job.name}</h4>
											<span class="px-2 py-1 text-xs rounded-full {getJobStatusColor(job.state)}">
												{job.state}
											</span>
										</div>
										<div class="text-sm text-gray-500">
											<div>Runs on: {job.runs_on}</div>
											<div>Steps: {job.steps.length}</div>
											{#if job.needs.length > 0}
												<div>Needs: {job.needs.join(', ')}</div>
											{/if}
										</div>
									</button>
								{/each}
							</div>
						</div>
					{/each}
				</div>
			{:else}
				<div class="text-center py-12">
					<p class="text-gray-500">No workflows found. Create a .loom.yml file in your project.</p>
				</div>
			{/if}
		</div>

		<!-- Selected Job Details -->
		{#if selectedJob}
			<div class="bg-white rounded-lg shadow">
				<div class="px-6 py-4 border-b">
					<h3 class="text-lg font-medium text-gray-900">Job: {selectedJob.name}</h3>
					<div class="flex items-center space-x-4 mt-2">
						<span class="px-2 py-1 text-xs rounded-full {getJobStatusColor(selectedJob.state)}">
							{selectedJob.state}
						</span>
						<span class="text-sm text-gray-500">Runs on: {selectedJob.runs_on}</span>
					</div>
				</div>

				<div class="p-6">
					<h4 class="font-medium text-gray-900 mb-4">Steps</h4>
					<div class="space-y-3">
						{#each selectedJob.steps as step}
							<div class="flex items-start space-x-3 p-3 bg-gray-50 rounded-lg">
								<div class="w-2 h-2 bg-gray-400 rounded-full mt-2"></div>
								<div class="flex-1">
									<h5 class="font-medium text-gray-900">{step.name}</h5>
									<code class="text-sm text-gray-600 bg-white px-2 py-1 rounded mt-1 block">
										{step.run}
									</code>
								</div>
							</div>
						{/each}
					</div>
				</div>
			</div>
		{/if}

		<!-- WebSocket Error -->
		{#if $wsError}
			<div class="mt-4 p-4 bg-red-50 border border-red-200 rounded-lg">
				<div class="flex items-center">
					<div class="w-2 h-2 bg-red-500 rounded-full mr-2"></div>
					<span class="text-red-800">{$wsError}</span>
				</div>
			</div>
		{/if}
	</div>
</div>