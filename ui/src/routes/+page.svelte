<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import {
		getSystemStatus,
		getWorkflows,
		startWorkflow,
		stopWorkflow
	} from '$lib/orchestrator.remote.js';
	import {
		connectWebSocket,
		disconnectWebSocket,
		wsConnected,
		wsError
	} from '$lib/stores/websocket.js';
	import type { Workflow, Job } from '$lib/orchestrator.remote.js';

	// shadcn-svelte components
	import {
		Card,
		CardContent,
		CardDescription,
		CardHeader,
		CardTitle
	} from '$lib/components/ui/card';
	import { Button } from '$lib/components/ui/button';
	import { Badge } from '$lib/components/ui/badge';
	import { Alert, AlertDescription } from '$lib/components/ui/alert';
	import { Tabs, TabsContent, TabsList, TabsTrigger } from '$lib/components/ui/tabs';
	import {
		Table,
		TableBody,
		TableCell,
		TableHead,
		TableHeader,
		TableRow
	} from '$lib/components/ui/table';
	import { Progress } from '$lib/components/ui/progress';

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

	// Get job status badge variant
	function getJobStatusVariant(state: Job['state']) {
		switch (state) {
			case 'success':
				return 'default';
			case 'running':
				return 'secondary';
			case 'failed':
				return 'destructive';
			case 'pending':
				return 'outline';
			default:
				return 'outline';
		}
	}

	// Get job status color for progress bars
	function getJobStatusColor(state: Job['state']) {
		switch (state) {
			case 'success':
				return 'bg-green-500';
			case 'running':
				return 'bg-blue-500';
			case 'failed':
				return 'bg-red-500';
			case 'pending':
				return 'bg-gray-400';
			default:
				return 'bg-gray-400';
		}
	}
</script>

<svelte:head>
	<title>Loom - Self-hosted Actions Runner</title>
</svelte:head>

<div class="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100">
	<!-- Header -->
	<header class="bg-white/80 backdrop-blur-sm shadow-sm border-b border-slate-200">
		<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
			<div class="flex justify-between items-center py-6">
				<div class="flex items-center space-x-4">
					<div class="flex items-center space-x-3">
						<div
							class="w-10 h-10 bg-gradient-to-br from-blue-500 to-purple-600 rounded-lg flex items-center justify-center"
						>
							<span class="text-white font-bold text-lg">🧵</span>
						</div>
						<div>
							<h1 class="text-2xl font-bold text-slate-900">Loom</h1>
							<p class="text-sm text-slate-500">Self-hosted Actions Runner</p>
						</div>
					</div>
				</div>

				<!-- System Status -->
				<div class="flex items-center space-x-6">
					<div class="flex items-center space-x-2">
						<div class="w-2 h-2 bg-emerald-500 rounded-full animate-pulse"></div>
						<span class="text-sm font-medium text-slate-600">System Online</span>
					</div>

					<!-- WebSocket Status -->
					{#if $wsConnected}
						<Badge variant="default" class="bg-emerald-100 text-emerald-700 border-emerald-200">
							<div class="w-2 h-2 bg-emerald-500 rounded-full mr-2 animate-pulse"></div>
							Live Logs
						</Badge>
					{:else}
						<Badge variant="destructive">
							<div class="w-2 h-2 bg-red-500 rounded-full mr-2"></div>
							Logs Offline
						</Badge>
					{/if}
				</div>
			</div>
		</div>
	</header>

	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
		<!-- Main Content with Tabs -->
		<Tabs value="workflows" class="space-y-6">
			<TabsList class="grid w-full grid-cols-2 lg:w-auto lg:grid-cols-2">
				<TabsTrigger value="workflows">Workflows</TabsTrigger>
				<TabsTrigger value="logs">Live Logs</TabsTrigger>
			</TabsList>

			<TabsContent value="workflows" class="space-y-6">
				<!-- Workflow Controls -->
				<Card>
					<CardHeader>
						<div class="flex items-center justify-between">
							<div>
								<CardTitle>Workflow Management</CardTitle>
								<CardDescription>Start, stop, and monitor your workflows</CardDescription>
							</div>
							<div class="flex space-x-2">
								<Button
									onclick={handleStartWorkflow}
									disabled={!selectedWorkflow}
									class="bg-emerald-600 hover:bg-emerald-700"
								>
									▶️ Start Workflow
								</Button>
								<Button
									onclick={handleStopWorkflow}
									disabled={!selectedWorkflow}
									variant="destructive"
								>
									⏹️ Stop Workflow
								</Button>
							</div>
						</div>
					</CardHeader>
				</Card>

				<!-- Workflows Grid -->
				{#if workflows.length > 0}
					<div class="grid gap-6">
						{#each workflows as workflow}
							<Card class="overflow-hidden">
								<CardHeader class="bg-gradient-to-r from-slate-50 to-slate-100">
									<div class="flex items-center justify-between">
										<div>
											<CardTitle class="text-xl">{workflow.name}</CardTitle>
											<CardDescription>
												Triggers: {workflow.on.join(', ')} • {Object.keys(workflow.jobs).length} jobs
											</CardDescription>
										</div>
										<Badge variant="outline" class="text-slate-600">
											{Object.keys(workflow.jobs).length} Jobs
										</Badge>
									</div>
								</CardHeader>
								<CardContent class="p-6">
									<!-- Jobs Grid -->
									<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
										{#each Object.values(workflow.jobs) as job}
											<Card
												class="cursor-pointer transition-all duration-200 hover:shadow-md hover:scale-[1.02] {selectedJob?.name ===
												job.name
													? 'ring-2 ring-blue-500 shadow-lg'
													: ''}"
												onclick={() => selectJob(job)}
											>
												<CardContent class="p-4">
													<div class="space-y-3">
														<div class="flex items-center justify-between">
															<h4 class="font-semibold text-slate-900 truncate">{job.name}</h4>
															<Badge variant={getJobStatusVariant(job.state)}>
																{job.state}
															</Badge>
														</div>

														<div class="space-y-2 text-sm text-slate-600">
															<div class="flex items-center space-x-2">
																<span class="font-medium">Platform:</span>
																<Badge variant="outline" class="text-xs">{job.runs_on}</Badge>
															</div>
															<div class="flex items-center space-x-2">
																<span class="font-medium">Steps:</span>
																<span>{job.steps.length}</span>
															</div>
															{#if job.needs.length > 0}
																<div class="flex items-center space-x-2">
																	<span class="font-medium">Depends on:</span>
																	<span class="truncate">{job.needs.join(', ')}</span>
																</div>
															{/if}
														</div>

														<!-- Progress indicator -->
														<div class="space-y-1">
															<div class="flex justify-between text-xs text-slate-500">
																<span>Progress</span>
																<span
																	>{job.state === 'success'
																		? '100%'
																		: job.state === 'running'
																			? '50%'
																			: '0%'}</span
																>
															</div>
															<Progress
																value={job.state === 'success'
																	? 100
																	: job.state === 'running'
																		? 50
																		: 0}
																class="h-2"
															/>
														</div>
													</div>
												</CardContent>
											</Card>
										{/each}
									</div>
								</CardContent>
							</Card>
						{/each}
					</div>
				{:else}
					<Card>
						<CardContent class="text-center py-12">
							<div class="space-y-4">
								<div
									class="w-16 h-16 bg-slate-100 rounded-full flex items-center justify-center mx-auto"
								>
									<span class="text-2xl">📄</span>
								</div>
								<div>
									<h3 class="text-lg font-semibold text-slate-900">No workflows found</h3>
									<p class="text-slate-500">
										Create a .loom.yml file in your project to get started
									</p>
								</div>
							</div>
						</CardContent>
					</Card>
				{/if}
			</TabsContent>

			<TabsContent value="logs" class="space-y-6">
				<Card>
					<CardHeader>
						<CardTitle>Live Logs</CardTitle>
						<CardDescription>Real-time streaming logs from your workflows</CardDescription>
					</CardHeader>
					<CardContent>
						<div class="bg-slate-900 rounded-lg p-4 font-mono text-sm text-green-400 min-h-[400px]">
							<div class="text-slate-400">Waiting for logs...</div>
						</div>
					</CardContent>
				</Card>
			</TabsContent>
		</Tabs>

		<!-- Selected Job Details -->
		{#if selectedJob}
			<Card class="mt-6">
				<CardHeader class="bg-gradient-to-r from-blue-50 to-indigo-50">
					<div class="flex items-center justify-between">
						<div>
							<CardTitle class="text-xl flex items-center space-x-3">
								<span>🔧</span>
								<span>{selectedJob.name}</span>
							</CardTitle>
							<CardDescription class="mt-2">
								Job execution details and step information
							</CardDescription>
						</div>
						<div class="flex items-center space-x-3">
							<Badge variant={getJobStatusVariant(selectedJob.state)} class="text-sm">
								{selectedJob.state}
							</Badge>
							<Badge variant="outline" class="text-slate-600">
								{selectedJob.runs_on}
							</Badge>
						</div>
					</div>
				</CardHeader>
				<CardContent class="p-6">
					<div class="space-y-6">
						<!-- Job Overview -->
						<div class="grid grid-cols-1 md:grid-cols-3 gap-4">
							<div class="bg-slate-50 rounded-lg p-4">
								<div class="text-sm font-medium text-slate-600">Platform</div>
								<div class="text-lg font-semibold text-slate-900">{selectedJob.runs_on}</div>
							</div>
							<div class="bg-slate-50 rounded-lg p-4">
								<div class="text-sm font-medium text-slate-600">Steps</div>
								<div class="text-lg font-semibold text-slate-900">{selectedJob.steps.length}</div>
							</div>
							<div class="bg-slate-50 rounded-lg p-4">
								<div class="text-sm font-medium text-slate-600">Dependencies</div>
								<div class="text-lg font-semibold text-slate-900">
									{selectedJob.needs.length > 0 ? selectedJob.needs.length : 'None'}
								</div>
							</div>
						</div>

						<!-- Steps Table -->
						<div>
							<h4 class="text-lg font-semibold text-slate-900 mb-4">Execution Steps</h4>
							<div class="space-y-3">
								{#each selectedJob.steps as step, index}
									<Card class="border-l-4 border-l-blue-500">
										<CardContent class="p-4">
											<div class="flex items-start space-x-4">
												<div class="flex-shrink-0">
													<div
														class="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center"
													>
														<span class="text-sm font-semibold text-blue-600">{index + 1}</span>
													</div>
												</div>
												<div class="flex-1 min-w-0">
													<h5 class="font-semibold text-slate-900 mb-2">{step.name}</h5>
													<div
														class="bg-slate-900 rounded-lg p-3 font-mono text-sm text-green-400 overflow-x-auto"
													>
														<code>{step.run}</code>
													</div>
												</div>
											</div>
										</CardContent>
									</Card>
								{/each}
							</div>
						</div>

						<!-- Dependencies -->
						{#if selectedJob.needs.length > 0}
							<div>
								<h4 class="text-lg font-semibold text-slate-900 mb-4">Dependencies</h4>
								<div class="flex flex-wrap gap-2">
									{#each selectedJob.needs as dependency}
										<Badge variant="secondary" class="text-sm">
											{dependency}
										</Badge>
									{/each}
								</div>
							</div>
						{/if}
					</div>
				</CardContent>
			</Card>
		{/if}

		<!-- WebSocket Error -->
		{#if $wsError}
			<Alert variant="destructive" class="mt-6">
				<AlertDescription class="flex items-center space-x-2">
					<div class="w-2 h-2 bg-red-500 rounded-full"></div>
					<span>{$wsError}</span>
				</AlertDescription>
			</Alert>
		{/if}
	</div>
</div>
