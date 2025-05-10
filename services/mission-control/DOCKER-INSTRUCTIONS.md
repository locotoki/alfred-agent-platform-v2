# Running Mission Control in Docker

This document explains how to run the Mission Control service as a Docker container, consistent with the other services in the Alfred Agent Platform.

## Why Use Docker?

Running Mission Control in Docker provides several benefits:

1. **Consistency**: All services in the platform follow the same deployment model
2. **Simplified Configuration**: Service URLs use Docker network hostnames
3. **Portability**: The entire platform can be deployed with a single command
4. **Better Dependency Management**: Service dependencies are properly defined
5. **Improved Development Experience**: Consistent development and production environments

## Prerequisites

- Docker and Docker Compose installed
- The Alfred Agent Platform repository checked out

## Running the Containerized Service

### Option 1: Use the convenience script

We've provided a script that builds and runs the containerized Mission Control service:

```bash
cd /path/to/alfred-agent-platform-v2
./services/mission-control/start-container.sh
```

This script:
1. Builds the Mission Control Docker image
2. Stops any existing Mission Control containers
3. Starts the Mission Control container
4. Maps port 3007 on the host to port 3000 in the container

### Option 2: Use Docker Compose directly

You can also use Docker Compose directly:

```bash
cd /path/to/alfred-agent-platform-v2
docker-compose -f docker-compose.yml -f docker-compose.override.mission-control.yml up -d --build mission-control
```

### Accessing the Service

After starting the containerized service, you can access it at:

```
http://localhost:3007
```

### Stopping the Service

To stop the containerized service:

```bash
cd /path/to/alfred-agent-platform-v2
docker-compose -f docker-compose.yml -f docker-compose.override.mission-control.yml stop mission-control
```

## Development Workflow

For development with the containerized service:

1. The `src` and `public` directories are mounted as volumes, so changes to these files are reflected without rebuilding
2. After making changes to configuration files or package.json, you'll need to rebuild the container

## Troubleshooting

### Service Not Starting

Check the logs:

```bash
docker-compose -f docker-compose.yml -f docker-compose.override.mission-control.yml logs mission-control
```

### Port Conflicts

If port 3007 is already in use, you can modify the port mapping in `docker-compose.override.mission-control.yml`.

### API Connection Issues

Make sure the service has access to:
- Social Intelligence Agent (http://social-intel:9000)
- Financial Tax Agent (http://financial-tax:9003)
- Legal Compliance Agent (http://legal-compliance:9002)

These are automatically configured in the Docker Compose file.