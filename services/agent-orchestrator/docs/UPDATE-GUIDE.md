# Updating Alfred Agent Orchestrator

This guide explains how to update the Alfred Agent Orchestrator to the latest version.

## Prerequisites

- Docker and Docker Compose installed
- Git installed
- Access to the Alfred Agent Orchestrator repository

## Update Process

### 1. Pull the Latest Code

First, navigate to the orchestrator directory and pull the latest code:

```bash
cd /home/locotoki/alfred-agent-orchestrator
git pull
```

This will fetch and merge the latest changes from the repository.

### 2. Rebuild and Restart the Container

After pulling the latest code, rebuild and restart the container:

```bash
# Stop the current container
docker-compose down

# Rebuild and start with the latest code
docker-compose up -d --build
```

This process:
1. Stops the current container
2. Rebuilds the container image with the latest code
3. Starts a new container with the updated image

### 3. Verify the Update

Check that the container is running with the updated code:

```bash
# Check container status
docker ps | grep agent-orchestrator

# Check container logs
docker logs agent-orchestrator
```

Verify that you can access the orchestrator UI at http://localhost:8080.

## Troubleshooting Common Issues

### Port Conflicts

If you encounter port conflicts, you can modify the port mapping in `docker-compose.yml`:

```yaml
ports:
  - "8090:8080"  # Change 8080 to an available port
```

### Build Failures

If the build fails, check for errors in the build log:

```bash
docker-compose build --no-cache agent-orchestrator
```

Common issues include:
- Dependency conflicts
- Syntax errors in the code
- Missing environment variables

### Connection Issues

If the orchestrator cannot connect to the Social Intelligence Agent:

1. Verify that the Social Intelligence Agent is running:
   ```bash
   docker ps | grep social-intel
   ```

2. Check the network configuration in `docker-compose.yml`:
   ```yaml
   networks:
     default:
       name: alfred-network
       external: true
   ```

3. Update the environment variables in `.env`:
   ```
   VITE_API_URL=http://social-intel:9000
   VITE_SOCIAL_INTEL_URL=http://social-intel:9000
   ```

## Development Mode Updates

If you're working in development mode:

```bash
# Start in development mode after update
./start-dev.sh
```

This will:
- Start the Vite development server
- Enable hot module replacement
- Mount your local code as volumes
- Show detailed logs in the console

## Production Mode Updates

For production deployments:

```bash
# Start in production mode after update
./start-prod.sh
```

This will:
- Build an optimized production bundle
- Use a static file server
- Set environment to production
- Run in detached mode with container health checks