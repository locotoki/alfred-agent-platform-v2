# Simplified Mission Control

A lightweight, streamlined implementation of the Mission Control UI for the Alfred Agent Platform v2.

## Overview

This simplified version of Mission Control provides a containerized, efficient interface for:

- Monitoring agent statuses and platform health
- Running Niche-Scout workflows for YouTube trend identification
- Running Seed-to-Blueprint workflows for YouTube channel strategy creation
- Accessing a unified dashboard for platform metrics

## Quick Start

```bash
# Start the Mission Control container
./start.sh
```

Then visit:
- Dashboard: http://localhost:3007/
- Niche-Scout Workflow: http://localhost:3007/workflows/niche-scout
- Seed-to-Blueprint Workflow: http://localhost:3007/workflows/seed-to-blueprint

## Technical Details

- **Server**: Express.js
- **UI**: HTML/CSS/JavaScript
- **Container**: Docker
- **Port**: 3007

## Key Features

1. **Dashboard**:
   - System metrics overview
   - Agent status monitoring
   - Activity feed
   - Workflow management interface

2. **Niche-Scout Workflow**:
   - Three-step wizard interface
   - Category and subcategory selection
   - Research parameter configuration
   - Results visualization with multiple tabs

3. **Seed-to-Blueprint Workflow**:
   - Three-step wizard interface
   - Seed video or niche-based input options
   - YouTube channel strategy generation
   - Comprehensive blueprint visualization with content pillars

## Architecture

The application is structured as a single-container service that provides a simplified frontend for the Alfred Agent Platform. In a full implementation, it connects to the following services:

- **Social Intelligence Agent**: For YouTube workflow functionality
- **Financial Tax Agent**: For financial analysis
- **Legal Compliance Agent**: For regulatory checks
- **Supabase**: For data storage and authentication

## Integration with Main Project

This simplified Mission Control can run alongside the full-featured implementation, providing a lightweight alternative for basic monitoring and workflow execution when needed.

To run as part of the main project:

```bash
# From the main project root
docker-compose -f docker-compose.yml -f docker-compose.override.simplified-mc.yml up -d mission-control-simplified
```

## Development

To run in development mode (without Docker):

```bash
# Install dependencies
npm install

# Start development server
npm run dev
```

## Directory Structure

```
/
├── Dockerfile            # Container definition
├── docker-compose.yml    # Docker Compose configuration
├── package.json          # Node.js dependencies
├── server.js             # Express server
├── start.sh              # Start script
└── public/               # Static files
    ├── index.html        # Dashboard page
    ├── niche-scout.html  # Niche-Scout workflow page
    └── seed-to-blueprint.html  # Seed-to-Blueprint workflow page
```

## Customization

To add or modify endpoints, edit the `server.js` file. For UI changes, modify the HTML files in the `public` directory.

## Social Intelligence Integration

The Simplified Mission Control now integrates with the Social Intelligence Agent for executing YouTube workflow operations. See [INTEGRATION.md](./INTEGRATION.md) for detailed instructions.

### Key Features

- Real-time agent status monitoring
- Direct workflow execution via the Social Intelligence Agent
- Graceful fallback to mock data when needed
- Comprehensive error handling and logging

### Running with Integration

To run with Social Intelligence integration:

```bash
# For local development
npm install
node server.js

# For Docker deployment
docker-compose up -d
```

### Testing the Integration

```bash
# Test all API endpoints
npm test

# Test direct connection to Social Intelligence Agent
npm run test:social-intel

# Run load tests
npm run test:load

# Export and validate load test results
k6 run scripts/proxy_load.js --summary-export=result.json
npm run test:thresholds
```

## Load Testing

The API includes automated load testing to ensure performance meets our standards:

- **p99 Latency**: Must be under 800ms
- **Error Rate**: Must be under 3%

These tests run automatically on all PRs to the main branch.

### CI Integration

The GitHub Actions workflow will:
1. Set up the test environment with Docker Compose
2. Run k6 load tests against the API
3. Validate results against performance thresholds
4. Post test results as PR comments

All PRs must pass these performance thresholds before being merged.

## Future Improvements

- Add authentication via Supabase integration
- Create persistent storage for workflow results
- Implement real-time notifications
- Add unified logging system
- Support additional workflows (Financial Analysis, Legal Compliance)
