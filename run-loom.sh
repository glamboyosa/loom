#!/bin/bash

# Loom One-Liner Runner
# Downloads and runs Loom from Docker Hub

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[LOOM]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[LOOM]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[LOOM]${NC} $1"
}

print_error() {
    echo -e "${RED}[LOOM]${NC} $1"
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

print_status "🚀 Starting Loom from Docker Hub..."

# Create data directory if it doesn't exist
mkdir -p ./loom-data

# Run Loom container
docker run -d \
  --name loom \
  -p 4000:4000 \
  -p 5173:5173 \
  -v "$(pwd)/loom-data:/app/data" \
  -v "/var/run/docker.sock:/var/run/docker.sock" \
  -v "$(pwd):/workspace" \
  -e MIX_ENV=prod \
  -e PORT=4000 \
  --restart unless-stopped \
  loom/orchestrator:latest

# Wait for services to start
print_status "⏳ Waiting for services to start..."
sleep 5

# Check if services are running
if docker ps | grep -q loom; then
    print_success "🎉 Loom is running!"
    echo ""
    print_status "Access points:"
    echo "  📊 Dashboard: http://localhost:5173"
    echo "  🔌 API: http://localhost:4000"
    echo "  📡 WebSocket: ws://localhost:4000/socket/websocket"
    echo ""
    print_status "To stop Loom: docker stop loom"
    print_status "To view logs: docker logs -f loom"
    print_status "To remove Loom: docker rm -f loom"
else
    print_error "Failed to start Loom. Check logs with: docker logs loom"
    exit 1
fi
