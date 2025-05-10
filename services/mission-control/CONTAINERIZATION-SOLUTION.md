# Mission Control Containerization Solution

This document explains the containerization solution for the Mission Control service.

## Overview

The Mission Control service is now containerized using Docker and can be run alongside other services in the platform. It's accessible at http://localhost:3007.

## Implementation Details

### Dockerfile

The Dockerfile uses a simple, single-stage build process:

- Base image: `node:18-alpine`
- Working directory: `/app`
- Exposes port 3000 (internal container port)
- Maps to port 3007 on the host (defined in docker-compose)
- Uses standard npm commands for build and run

### Docker Compose Configuration

The service is defined in `docker-compose.override.mission-control.yml`:

- Port mapping: `3007:3000`
- Dependencies on required services (supabase, social-intel, etc.)
- Volume mounts for source code and node_modules
- Environment variables including API URLs and service connections
- Health check configuration

### Environment Variables

Critical environment variables for proper operation:

- `NODE_ENV=production`
- `PORT=3000` (container internal port)
- `NEXT_PUBLIC_API_URL=http://localhost:3007` (external access port)
- `SOCIAL_INTEL_SERVICE_URL=http://social-intel:9000` (internal Docker network reference)

## How to Use

To run the containerized Mission Control service:

1. Ensure Docker and Docker Compose are installed
2. Run the start script: `bash services/mission-control/start-container.sh`
3. Access the application at http://localhost:3007

## Troubleshooting

If you encounter issues:

1. Check Docker logs: `docker logs mission-control`
2. Verify port availability: `netstat -tulpn | grep 3007`
3. Ensure dependent services are running: `docker-compose ps`
4. Restart the container: `docker-compose restart mission-control`

## Development Notes

For local development without Docker:

1. Use `npm run dev` to start the development server
2. Access the application at http://localhost:3007

The code is configured to consistently use port 3007 in both containerized and local development environments.