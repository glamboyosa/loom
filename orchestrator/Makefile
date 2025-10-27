# Orchestrator Makefile
# Hides complexity behind simple commands

.PHONY: help dev test clean compile deps

# Default target
help:
	@echo "🚀 Orchestrator Commands:"
	@echo ""
	@echo "  make dev      - Start IEx with Mix (interactive development)"
	@echo "  make dev-full - Start full development environment (backend + frontend)"
	@echo "  make test     - Run tests"
	@echo "  make compile  - Compile the project"
	@echo "  make deps     - Install dependencies"
	@echo "  make clean    - Clean build artifacts"
	@echo "  make test-entry - Test complete system with entry point"
	@echo "  make test-communication - Test component communication"
	@echo "  make help     - Show this help"

# Start interactive development environment
dev:
	@echo "🔧 Starting IEx with Mix..."
	@echo "💡 Try: Orchestrator.start()"
	@echo "💡 Then: Orchestrator.test_workflow()"
	@echo ""
	iex -S mix

# Start full development environment (backend + frontend)
dev-full:
	@echo "🚀 Starting full development environment (backend + frontend)..."
	@echo "This will start both Elixir backend and SvelteKit frontend"
	@echo "Access: http://localhost:5173 (Dashboard) + http://localhost:4000 (API)"
	@echo ""
	@echo "Starting in 3 seconds... (Press Ctrl+C to cancel)"
	@sleep 3
	@cd .. && ./dev.sh

# Run tests
test:
	@echo "🧪 Running tests..."
	mix test

# Compile project
compile:
	@echo "🔨 Compiling project..."
	mix compile

# Install dependencies
deps:
	@echo "📦 Installing dependencies..."
	mix deps.get

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	mix clean
	rm -rf _build/
	rm -rf deps/

# Quick test of our parser
test-parser: compile
	@echo "🧪 Testing YAML parser..."
	@echo "alias Orchestrator.ConfigParser" > test_quick.exs
	@echo "alias Orchestrator.DAG" >> test_quick.exs
	@echo "case ConfigParser.parse_file(\"test.loom.yml\") do" >> test_quick.exs
	@echo "  {:ok, jobs} ->" >> test_quick.exs
	@echo "    IO.puts(\"✅ Parsed \" <> to_string(length(jobs)) <> \" jobs\")" >> test_quick.exs
	@echo "    dag = DAG.build(jobs)" >> test_quick.exs
	@echo "    IO.puts(\"✅ DAG built\")" >> test_quick.exs
	@echo "    ready = DAG.ready_jobs(dag)" >> test_quick.exs
	@echo "    IO.puts(\"✅ Ready jobs: \" <> inspect(ready))" >> test_quick.exs
	@echo "  {:error, _reason} ->" >> test_quick.exs
	@echo "    IO.puts(\"❌ Error occurred\")" >> test_quick.exs
	@echo "end" >> test_quick.exs
	mix run test_quick.exs
	rm test_quick.exs

# Test the complete system with entry point
test-entry: compile
	@echo "🧪 Testing Orchestrator entry point..."
	mix run test_entry_point.exs

# Test communication between components
test-communication: compile
	@echo "🧪 Testing component communication..."
	mix run test_communication.exs
