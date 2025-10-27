#!/bin/bash

# Loom Development Script
# Runs both Elixir backend and SvelteKit frontend

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[LOOM-DEV]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[LOOM-DEV]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[LOOM-DEV]${NC} $1"
}

print_error() {
    echo -e "${RED}[LOOM-DEV]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "orchestrator/mix.exs" ] || [ ! -f "ui/package.json" ]; then
    print_error "Please run this script from the Loom root directory"
    exit 1
fi

print_status "Starting Loom development environment..."

# Function to cleanup background processes
cleanup() {
    print_status "Shutting down..."
    if [ ! -z "$BACKEND_PID" ]; then
        kill $BACKEND_PID 2>/dev/null || true
    fi
    if [ ! -z "$FRONTEND_PID" ]; then
        kill $FRONTEND_PID 2>/dev/null || true
    fi
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Start Elixir backend
print_status "Starting Elixir backend..."
cd orchestrator

# Check if dependencies are installed
if [ ! -d "deps" ]; then
    print_status "Installing Elixir dependencies..."
    mix deps.get
fi

# Check if database is set up
if [ ! -f "priv/dev.db" ]; then
    print_status "Setting up database..."
    mix ecto.setup
fi

# Start Phoenix server in background
mix phx.server &
BACKEND_PID=$!

# Wait a moment for backend to start
sleep 3

# Check if backend started successfully
if ! kill -0 $BACKEND_PID 2>/dev/null; then
    print_error "Failed to start Elixir backend"
    exit 1
fi

print_success "Elixir backend started (PID: $BACKEND_PID)"

# Start SvelteKit frontend
print_status "Starting SvelteKit frontend..."
cd ../ui

# Check if dependencies are installed
if [ ! -d "node_modules" ]; then
    print_status "Installing Node.js dependencies..."
    pnpm install
fi

# Start SvelteKit dev server in background
pnpm dev &
FRONTEND_PID=$!

# Wait a moment for frontend to start
sleep 3

# Check if frontend started successfully
if ! kill -0 $FRONTEND_PID 2>/dev/null; then
    print_error "Failed to start SvelteKit frontend"
    cleanup
    exit 1
fi

print_success "SvelteKit frontend started (PID: $FRONTEND_PID)"

print_success "🎉 Loom development environment is running!"
echo ""
print_status "Access points:"
echo "  📊 Dashboard: http://localhost:5173"
echo "  🔌 API: http://localhost:4000"
echo "  📡 WebSocket: ws://localhost:4000/socket/websocket"
echo ""
print_status "Press Ctrl+C to stop all services"

# Wait for user to stop
wait
