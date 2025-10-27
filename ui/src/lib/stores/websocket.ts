import { writable, derived } from 'svelte/store';
import { Socket } from 'phoenix';
import type { LogEntry } from '../orchestrator.remote.js';

// WebSocket connection state
export const wsConnected = writable(false);
export const wsError = writable<string | null>(null);

// Log entries store
export const logEntries = writable<LogEntry[]>([]);

// Phoenix Socket instance
let socket: Socket | null = null;
let logChannel: any = null;

/**
 * Connect to the Elixir orchestrator Phoenix WebSocket
 */
export function connectWebSocket() {
	if (socket?.isConnected()) {
		return; // Already connected
	}

	try {
		// Connect to the Phoenix WebSocket
		socket = new Socket('ws://localhost:4000/socket/websocket', {
			params: {}
		});

		socket.connect();

		socket.onOpen(() => {
			console.log('🔌 Connected to Loom orchestrator Phoenix WebSocket');
			wsConnected.set(true);
			wsError.set(null);
		});

		socket.onClose(() => {
			console.log('🔌 Disconnected from Loom orchestrator Phoenix WebSocket');
			wsConnected.set(false);
			
			// Attempt to reconnect after 3 seconds
			setTimeout(() => {
				if (!socket?.isConnected()) {
					connectWebSocket();
				}
			}, 3000);
		});

		socket.onError((error) => {
			console.error('Phoenix WebSocket error:', error);
			wsError.set('Failed to connect to orchestrator');
			wsConnected.set(false);
		});

	} catch (error) {
		console.error('Failed to create Phoenix WebSocket connection:', error);
		wsError.set('Failed to create WebSocket connection');
	}
}

/**
 * Disconnect from Phoenix WebSocket
 */
export function disconnectWebSocket() {
	if (logChannel) {
		logChannel.leave();
		logChannel = null;
	}
	if (socket) {
		socket.disconnect();
		socket = null;
		wsConnected.set(false);
	}
}

/**
 * Subscribe to logs for a specific job
 */
export function subscribeToJobLogs(jobName: string) {
	if (socket?.isConnected()) {
		// Leave previous channel if exists
		if (logChannel) {
			logChannel.leave();
		}

		// Join the specific job log channel
		logChannel = socket.channel(`logs:${jobName}`, {});
		
		logChannel.on('new_log', (payload: LogEntry) => {
			console.log('📝 Received log:', payload);
			logEntries.update(logs => [...logs, payload]);
		});

		logChannel.join()
			.receive('ok', () => {
				console.log(`📡 Joined logs channel for job: ${jobName}`);
			})
			.receive('error', (resp) => {
				console.error('Failed to join logs channel:', resp);
			});
	}
}

/**
 * Subscribe to all logs
 */
export function subscribeToAllLogs() {
	if (socket?.isConnected()) {
		// Leave previous channel if exists
		if (logChannel) {
			logChannel.leave();
		}

		// Join the all logs channel
		logChannel = socket.channel('logs:all', {});
		
		logChannel.on('new_log', (payload: LogEntry) => {
			console.log('📝 Received log:', payload);
			logEntries.update(logs => [...logs, payload]);
		});

		logChannel.join()
			.receive('ok', () => {
				console.log('📡 Joined all logs channel');
			})
			.receive('error', (resp) => {
				console.error('Failed to join all logs channel:', resp);
			});
	}
}

/**
 * Unsubscribe from job logs
 */
export function unsubscribeFromJobLogs(jobName: string) {
	if (logChannel) {
		logChannel.leave();
		logChannel = null;
		console.log(`📡 Left logs channel for job: ${jobName}`);
	}
}

/**
 * Clear all logs
 */
export function clearLogs() {
	logEntries.set([]);
}

// Derived stores for filtered logs
export const logsByJob = derived(
	logEntries,
	($logs) => {
		const grouped: Record<string, LogEntry[]> = {};
		$logs.forEach(log => {
			if (!grouped[log.job_name]) {
				grouped[log.job_name] = [];
			}
			grouped[log.job_name].push(log);
		});
		return grouped;
	}
);

export const recentLogs = derived(
	logEntries,
	($logs) => $logs.slice(-100) // Last 100 log entries
);
