<script lang="ts">
	import { page } from '$app/stores';
</script>

<nav class="bg-white shadow-sm border-b">
	<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
		<div class="flex space-x-8">
			<a
				href="/"
				class="py-4 px-1 border-b-2 font-medium text-sm {$page.url.pathname === '/' ? 'border-blue-500 text-blue-600' : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'}"
			>
				🏠 Dashboard
			</a>
			<a
				href="/logs"
				class="py-4 px-1 border-b-2 font-medium text-sm {$page.url.pathname === '/logs' ? 'border-blue-500 text-blue-600' : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'}"
			>
				📝 Live Logs
			</a>
		</div>
	</div>
</nav>
