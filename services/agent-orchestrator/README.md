# Alfred Agent Orchestrator

A modern UI for orchestrating and monitoring AI agents in the Alfred Agent Platform v2.

## Overview

The Alfred Agent Orchestrator provides a user interface for:
- Running YouTube workflows (Niche-Scout and Seed-to-Blueprint)
- Monitoring agent status and activities
- Managing workflow history and scheduled workflows
- Visualizing agent performance and results

## Quick Start

### Development Mode

```bash
# Install dependencies
npm install

# Start the development server
npm run dev

# Or use the convenience script
./start-dev.sh
```

### Production Mode (Docker)

```bash
# Build and start the container
./start-prod.sh
```

## Integration with Alfred Agent Platform

The Orchestrator is designed to work with the Alfred Agent Platform v2. It connects to the Social Intelligence Agent for YouTube workflows and other agent services.

See [SETUP.md](./SETUP.md) for detailed setup instructions.

## Features

- **Agent Management**: View and control agent status
- **YouTube Workflows**: Run Niche-Scout and Seed-to-Blueprint workflows
- **Workflow History**: View past workflow executions and results
- **Scheduled Workflows**: Schedule and manage recurring workflows
- **Visualizations**: View trend visualizations and analytics

## Technology Stack

- **Frontend**: React with TypeScript
- **UI Components**: shadcn-ui
- **Styling**: Tailwind CSS
- **Build Tool**: Vite
- **Container**: Docker

## Configuration

Configure the application by modifying the `.env` file or using environment variables:

```
VITE_API_URL=http://localhost:9000
VITE_SOCIAL_INTEL_URL=http://localhost:9000
VITE_USE_MOCK_DATA=false
NODE_ENV=development
```

## Docker Deployment

For a full stack deployment with all required services:

```bash
# Start the full stack
docker-compose -f docker-compose.full.yml up -d
```

## Development

This project uses:
- TypeScript for type safety
- ESLint for code linting
- Vite for fast development and builds

### Available Scripts

- `npm run dev`: Start development server
- `npm run build`: Build for production
- `npm run lint`: Run linting
- `npm run preview`: Preview production build

## License

MIT