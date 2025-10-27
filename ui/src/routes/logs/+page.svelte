<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { getWorkflows, getJobLogs } from '$lib/orchestrator.remote.js';
	import {
		connectWebSocket,
		disconnectWebSocket,
		wsConnected,
		wsError,
		logEntries,
		logsByJob,
		subscribeToJobLogs,
		subscribeToAllLogs,
		unsubscribeFromJobLogs,
		clearLogs
	} from '$lib/stores/websocket.js';
	import type { Workflow, Job, LogEntry } from '$lib/orchestrator.remote.js';

	// Load workflows
	const workflows = await getWorkflows();

	// Reactive state
	let selectedWorkflow = $state<Workflow | null>(workflows[0] || null);
	let selectedJob = $state<Job | null>(null);
	let filterLevel = $state<LogEntry['level'] | 'all'>('all');
	let autoScroll = $state(true);

	onMount(() => {
		connectWebSocket();
	});

	onDestroy(() => {
		disconnectWebSocket();
	});

	// Subscribe to job logs when job is selected
	$effect(() => {
		if (selectedJob) {
			subscribeToJobLogs(selectedJob.name);
		} else {
			// Subscribe to all logs if no specific job is selected
			subscribeToAllLogs();
		}
	});

	// Get filtered logs
	const filteredLogs = $derived(
		$logEntries.filter((log) => {
			if (filterLevel !== 'all' && log.level !== filterLevel) return false;
			if (selectedJob && log.job_name !== selectedJob.name) return false;
			return true;
		})
	);

	// Auto-scroll to bottom
	$effect(() => {
		if (autoScroll && filteredLogs.length > 0) {
			setTimeout(() => {
				const container = document.getElementById('logs-container');
				if (container) {
					container.scrollTop = container.scrollHeight;
				}
			}, 100);
		}
	});

	function selectJob(job: Job) {
		selectedJob = job;
	}

	function getLogLevelColor(level: LogEntry['level']) {
		switch (level) {
			case 'error':
				return 'text-red-600 bg-red-100';
			case 'warn':
				return 'text-yellow-600 bg-yellow-100';
			case 'info':
				return 'text-blue-600 bg-blue-100';
			case 'debug':
				return 'text-gray-600 bg-gray-100';
			default:
				return 'text-gray-600 bg-gray-100';
		}
	}

	function formatTimestamp(timestamp: string) {
		return new Date(timestamp).toLocaleTimeString();
	}
</script>

<svelte:head>
	<title>Logs - Loom</title>
</svelte:head>

<div class="min-h-screen bg-gray-50">
	<!-- Page Header -->
	<div class="bg-white shadow-sm border-b">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="flex justify-between items-center py-4">
				<div class="flex items-center">
					<h1 class="text-xl font-bold text-gray-900">📝 Live Logs</h1>
				</div>

				<div class="flex items-center space-x-4">
					<!-- WebSocket Status -->
					{#if $wsConnected}
						<div class="flex items-center space-x-2">
							<div class="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
							<span class="text-sm text-gray-600">Live</span>
						</div>
					{:else}
						<div class="flex items-center space-x-2">
							<div class="w-2 h-2 bg-red-500 rounded-full"></div>
							<span class="text-sm text-red-600">Offline</span>
						</div>
					{/if}

					<!-- Controls -->
					<button
						onclick={clearLogs}
						class="px-3 py-1 text-sm bg-gray-200 text-gray-700 rounded hover:bg-gray-300"
					>
						Clear
					</button>

					<label class="flex items-center space-x-2">
						<input type="checkbox" bind:checked={autoScroll} class="rounded" />
						<span class="text-sm text-gray-600">Auto-scroll</span>
					</label>
				</div>
			</div>
		</div>
	</div>

	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
		<div class="grid grid-cols-1 lg:grid-cols-4 gap-6">
			<!-- Job Selection Sidebar -->
			<div class="lg:col-span-1">
				<div class="bg-white rounded-lg shadow p-4">
					<h3 class="font-medium text-gray-900 mb-4">Jobs</h3>

					{#if selectedWorkflow}
						<div class="space-y-2">
							{#each Object.values(selectedWorkflow.jobs) as job}
								<button
									onclick={() => selectJob(job)}
									class="w-full text-left p-3 rounded-lg hover:bg-gray-50 transition-colors {selectedJob?.name ===
									job.name
										? 'bg-blue-50 border border-blue-200'
										: 'border border-gray-200'}"
								>
									<div class="flex items-center justify-between">
										<span class="font-medium text-gray-900">{job.name}</span>
										<span
											class="px-2 py-1 text-xs rounded-full {job.state === 'success'
												? 'bg-green-100 text-green-600'
												: job.state === 'running'
													? 'bg-blue-100 text-blue-600'
													: job.state === 'failed'
														? 'bg-red-100 text-red-600'
														: 'bg-gray-100 text-gray-600'}"
										>
											{job.state}
										</span>
									</div>
									<div class="text-sm text-gray-500 mt-1">
										{job.steps.length} steps
									</div>
								</button>
							{/each}
						</div>
					{:else}
						<p class="text-gray-500 text-sm">No workflow selected</p>
					{/if}
				</div>

				<!-- Filter Controls -->
				<div class="bg-white rounded-lg shadow p-4 mt-4">
					<h3 class="font-medium text-gray-900 mb-4">Filter</h3>

					<div class="space-y-2">
						<label class="flex items-center space-x-2">
							<input type="radio" bind:group={filterLevel} value="all" class="rounded" />
							<span class="text-sm text-gray-600">All</span>
						</label>
						<label class="flex items-center space-x-2">
							<input type="radio" bind:group={filterLevel} value="info" class="rounded" />
							<span class="text-sm text-blue-600">Info</span>
						</label>
						<label class="flex items-center space-x-2">
							<input type="radio" bind:group={filterLevel} value="warn" class="rounded" />
							<span class="text-sm text-yellow-600">Warning</span>
						</label>
						<label class="flex items-center space-x-2">
							<input type="radio" bind:group={filterLevel} value="error" class="rounded" />
							<span class="text-sm text-red-600">Error</span>
						</label>
					</div>
				</div>
			</div>

			<!-- Logs Display -->
			<div class="lg:col-span-3">
				<div class="bg-white rounded-lg shadow">
					<div class="px-6 py-4 border-b">
						<h3 class="font-medium text-gray-900">
							{selectedJob ? `Logs: ${selectedJob.name}` : 'Select a job to view logs'}
						</h3>
						<div class="text-sm text-gray-500 mt-1">
							{filteredLogs.length} log entries
						</div>
					</div>

					<div id="logs-container" class="h-96 overflow-y-auto p-6 font-mono text-sm">
						{#if filteredLogs.length === 0}
							<div class="text-center text-gray-500 py-8">
								{#if selectedJob}
									No logs available for {selectedJob.name}
								{:else}
									Select a job to view its logs
								{/if}
							</div>
						{:else}
							<div class="space-y-1">
								{#each filteredLogs as log}
									<div class="flex items-start space-x-3 py-1">
										<span class="text-gray-400 text-xs mt-1 min-w-[60px]">
											{formatTimestamp(log.timestamp)}
										</span>
										<span
											class="px-2 py-1 text-xs rounded {getLogLevelColor(
												log.level
											)} min-w-[50px] text-center"
										>
											{log.level.toUpperCase()}
										</span>
										<span class="text-gray-600 min-w-[100px]">
											[{log.job_name}]
										</span>
										<span class="text-gray-500 min-w-[120px]">
											{log.step_name}:
										</span>
										<span class="text-gray-900 flex-1">
											{log.message}
										</span>
									</div>
								{/each}
							</div>
						{/if}
					</div>
				</div>
			</div>
		</div>

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
