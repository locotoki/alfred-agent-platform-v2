# Mission Control Production Deployment Guide

This document explains how to run the Mission Control service in production mode as part of the overall Docker environment.

## Fixed Issues

We've addressed several issues that were preventing Mission Control from running properly in production mode:

1. **Import Path Resolution**: Fixed import paths in components to use path aliases (`@/`) consistently
2. **Production Build Configuration**: Updated the Dockerfile to properly set NODE_ENV and run in production mode
3. **Docker Compose Configuration**: Created separate production and development configurations
4. **Volume Mounting**: Removed source code volume mounts in production mode

## Running in Production Mode

To start Mission Control in production mode (the default):

```bash
./services/mission-control/start-container.sh
```

This will:
1. Build the application using the production Dockerfile
2. Use the production docker-compose configuration
3. Run with `NODE_ENV=production`
4. Start the service using `npm start`

## Running in Development Mode

For development, you can still run with live-reload and source code mounting:

```bash
./services/mission-control/start-container.sh development
```

This will:
1. Build using the Dockerfile.dev configuration
2. Use the development docker-compose configuration
3. Run with `NODE_ENV=development`
4. Mount source files as volumes for live-reload
5. Start the service using `npm run dev`

## Integration with Other Services

The Mission Control service now properly integrates with the other services in the Docker environment:

- It connects to Social Intelligence at `http://social-intel:9000`
- It connects to Financial Tax at `http://financial-tax:9003`
- It connects to Legal Compliance at `http://legal-compliance:9002`

## Port Configuration

The Mission Control service:
- Runs on port 3000 inside the container
- Is mapped to port 3007 on the host
- Is accessible at http://localhost:3007

## Health Checks

The service includes a health check endpoint at `/api/health` which can be used to verify the service is running correctly.

## Troubleshooting

If you encounter issues:

1. **Check Docker Logs**:
   ```bash
   docker logs mission-control
   ```

2. **Build Issues**:
   If there are build failures, try building locally first:
   ```bash
   cd services/mission-control
   npm run build
   ```

3. **Import Path Issues**:
   Ensure all imports use `@/` path aliases instead of relative paths

4. **API Connection Issues**:
   Check that the API endpoints are correctly configured in the docker-compose file

5. **Port Conflicts**:
   Ensure port 3007 is not being used by another service