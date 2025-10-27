# 🐳 Docker Deployment Guide

This guide shows you how to deploy Loom as a self-hosted Actions runner using Docker.

## 🚀 Quick Start

### Option 1: Using the Loom Script (Recommended)

```bash
# Make the script executable (if not already)
chmod +x loom

# Start Loom
./loom start

# Check status
./loom status

# View logs
./loom logs

# Stop Loom
./loom stop
```

### Option 2: Using Docker Compose

```bash
# Start Loom
docker-compose up -d

# View logs
docker-compose logs -f loom

# Stop Loom
docker-compose down
```

### Option 3: Using Docker Run

```bash
# Build the image
docker build -t loom ./orchestrator

# Run Loom
docker run -d \
  --name loom-orchestrator \
  -p 4000:4000 \
  -v $(pwd):/workspace:ro \
  -v /var/run/docker.sock:/var/run/docker.sock \
  loom
```

## 📁 Project Structure

```
your-project/
├── .loom.yml              # Your workflow definition
├── loom                   # Loom runner script
├── docker-compose.yml     # Docker Compose configuration
└── nginx.conf            # Nginx configuration (optional)
```

## 🔧 Configuration

### Environment Variables

| Variable          | Default        | Description               |
| ----------------- | -------------- | ------------------------- |
| `MIX_ENV`         | `prod`         | Elixir environment        |
| `PORT`            | `4000`         | Port for the orchestrator |
| `SECRET_KEY_BASE` | Auto-generated | Secret key for sessions   |

### Volume Mounts

| Host Path              | Container Path         | Description                          |
| ---------------------- | ---------------------- | ------------------------------------ |
| `$(pwd)`               | `/workspace`           | Your project directory (read-only)   |
| `/var/run/docker.sock` | `/var/run/docker.sock` | Docker socket for running containers |
| `loom-data`            | `/app/data`            | Persistent data (database, logs)     |

## 🌐 Accessing Loom

Once running, you can access:

- **Dashboard**: http://localhost:4000
- **API**: http://localhost:4000/api/status
- **WebSocket**: ws://localhost:4000/socket/websocket

## 📝 Example .loom.yml

Create a `.loom.yml` file in your project root:

```yaml
name: "My Project CI"
on: [push, pull_request]

jobs:
  build:
    runs-on: node-18
    steps:
      - name: Install dependencies
        run: npm install
      - name: Run tests
        run: npm test
      - name: Build
        run: npm run build

  deploy:
    needs: [build]
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to staging
        run: echo "Deploying to staging..."
```

## 🔍 Monitoring

### Health Checks

Loom includes built-in health checks:

```bash
# Check if Loom is healthy
curl http://localhost:4000/api/status

# Expected response:
{
  "scheduler": "running",
  "runner": "running",
  "docker_runner": "running",
  "watcher": "running"
}
```

### Logs

```bash
# View all logs
./loom logs

# Or with docker-compose
docker-compose logs -f loom

# View specific service logs
docker-compose logs -f loom
```

## 🛠️ Development

### Building from Source

```bash
# Build the Docker image
docker build -t loom ./orchestrator

# Run in development mode
docker run -it --rm \
  -p 4000:4000 \
  -v $(pwd):/workspace \
  -v /var/run/docker.sock:/var/run/docker.sock \
  loom
```

### Debugging

```bash
# Access the container shell
docker exec -it loom-orchestrator /bin/bash

# Check container logs
docker logs loom-orchestrator

# Inspect container
docker inspect loom-orchestrator
```

## 🚀 Production Deployment

### Using Nginx (Optional)

For production, you can use the included Nginx configuration:

```bash
# Start with Nginx
docker-compose --profile production up -d

# This will start:
# - Loom orchestrator on port 4000
# - Nginx reverse proxy on ports 80/443
```

### SSL/HTTPS

To enable HTTPS:

1. Place your SSL certificates in `./ssl/`
2. Update `nginx.conf` to use HTTPS
3. Start with the production profile

### Environment Variables

Set production environment variables:

```bash
# Create .env file
cat > .env << EOF
SECRET_KEY_BASE=your-secret-key-here
MIX_ENV=prod
PORT=4000
EOF

# Start with environment file
docker-compose --env-file .env up -d
```

## 🔒 Security Considerations

### Docker Socket Access

Loom needs access to the Docker socket to run containers. This gives it significant privileges:

- **Development**: Mount `/var/run/docker.sock` (as shown in examples)
- **Production**: Consider using Docker-in-Docker or a more restricted approach

### Network Security

- Loom exposes port 4000 by default
- Use a reverse proxy (Nginx) for production
- Consider firewall rules to restrict access

### Data Persistence

- Database and logs are stored in the `loom-data` volume
- Backup this volume for data persistence
- Consider using external database for production

## 🐛 Troubleshooting

### Common Issues

**Docker not running:**

```bash
# Start Docker Desktop or Docker daemon
sudo systemctl start docker  # Linux
# Or start Docker Desktop on macOS/Windows
```

**Permission denied:**

```bash
# Fix Docker socket permissions
sudo chmod 666 /var/run/docker.sock
```

**Port already in use:**

```bash
# Check what's using port 4000
lsof -i :4000

# Stop the conflicting service or change the port
```

**Container won't start:**

```bash
# Check container logs
docker logs loom-orchestrator

# Check if the image built correctly
docker images | grep loom
```

### Getting Help

1. Check the logs: `./loom logs`
2. Verify Docker is running: `docker info`
3. Check the API status: `curl http://localhost:4000/api/status`
4. Review the troubleshooting section in the main README

## 📚 Next Steps

- [Main README](../README.md) - Complete project overview
- [Technical Documentation](../orchestrator/TECHNICAL_DOCS.md) - Deep dive into architecture
- [Integration Guide](../INTEGRATION.md) - Connecting UI to orchestrator

---

**Happy building with Loom!** 🧵
