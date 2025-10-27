# Multi-stage build for Loom Orchestrator
FROM elixir:1.17-alpine AS builder

# Install build dependencies
RUN apk add --no-cache build-base git

# Set working directory
WORKDIR /app

# Install hex and rebar
RUN mix local.hex --force && mix local.rebar --force

# Copy mix files
COPY mix.exs mix.lock ./

# Install dependencies
RUN mix deps.get --only prod

# Copy source code
COPY . .

# Build the release
RUN MIX_ENV=prod mix release

# Final stage
FROM alpine:latest

# Install runtime dependencies
RUN apk add --no-cache \
    docker-cli \
    bash \
    curl \
    ca-certificates

# Create non-root user
RUN addgroup -g 1000 loom && \
    adduser -D -s /bin/bash -u 1000 -G loom loom

# Set working directory
WORKDIR /app

# Copy the release from builder stage
COPY --from=builder /app/_build/prod/rel/orchestrator ./

# Create directories for data
RUN mkdir -p /app/data /app/workspace && \
    chown -R loom:loom /app

# Switch to non-root user
USER loom

# Expose port
EXPOSE 4000

# Set environment variables
ENV MIX_ENV=prod
ENV PORT=4000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:4000/api/status || exit 1

# Start the application
CMD ["./bin/orchestrator", "start"]
