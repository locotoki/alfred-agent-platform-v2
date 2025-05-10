# Alfred Agent Orchestrator Setup Guide

This document provides instructions for setting up and running the Alfred Agent Orchestrator, which serves as a user interface for the Alfred Agent Platform v2.

## Overview

The Alfred Agent Orchestrator is a React-based UI built with:
- Vite for fast development and optimized builds
- TypeScript for type safety
- React for UI components
- shadcn-ui for UI component library
- Tailwind CSS for styling

## Setup Options

There are three ways to run the Agent Orchestrator:

### 1. Standalone Development

Run the orchestrator locally for development:

```bash
# Install dependencies
npm install

# Start development server
npm run dev
```

The application will be available at http://localhost:5173

### 2. Docker Standalone

Run the orchestrator in a Docker container, connecting to existing services:

```bash
# Build and start the container
docker-compose up -d

# View logs
docker-compose logs -f
```

The application will be available at http://localhost:5173

### 3. Full Stack Deployment

Run the orchestrator with all required services:

```bash
# Build and start all containers
docker-compose -f docker-compose.full.yml up -d

# View logs
docker-compose -f docker-compose.full.yml logs -f agent-orchestrator
```

The application will be available at http://localhost:5173

## Environment Configuration

Configure the application by modifying the `.env` file:

```
# API URLs
VITE_API_URL=http://localhost:9000
VITE_SOCIAL_INTEL_URL=http://localhost:9000

# Environment
NODE_ENV=development
```

For production, you should update these values to point to your production services.

## Integration with Alfred Agent Platform v2

To integrate with the existing Alfred Agent Platform v2:

1. Make sure both systems are on the same Docker network:
   ```bash
   # Create network if it doesn't exist
   docker network create alfred-network
   ```

2. Update the environment variables to point to the correct services:
   ```
   VITE_API_URL=http://social-intel:9000
   VITE_SOCIAL_INTEL_URL=http://social-intel:9000
   ```

3. Start the orchestrator using the desired configuration.

## Building for Production

To build the application for production:

```bash
# Build the application
npm run build

# Preview the built application
npm run preview
```

## Connecting to Services

The orchestrator connects to the following services:

1. **Social Intelligence Agent** - For YouTube workflow features
2. **Supabase Database** - For user authentication and data persistence
3. **Redis** - For caching and pub/sub
4. **Qdrant** - For vector storage

Ensure these services are running and properly configured in your environment variables.