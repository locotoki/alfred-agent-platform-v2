# Mission Control UI

Mission Control is the centralized dashboard for monitoring and managing the Alfred Agent Platform. It provides a business-oriented view of the platform's metrics, agent status, and task management capabilities.

## Features

- **Dashboard**: Real-time overview of platform health, agent status, and recent activity
- **Agent Management**: Monitor and control individual agents in the platform
- **Task Management**: Create, monitor, and manage tasks across agents
- **Workflow Hub**: Run and schedule specialized workflows like YouTube research tools
- **Reporting**: View and export reports on platform performance

## YouTube Research Workflows

Mission Control includes specialized workflows for YouTube market research:

### Implemented Workflows

1. **Niche-Scout**:
   - Find trending YouTube niches with comprehensive growth metrics
   - Form for entering search queries with advanced options for category, time range, and demographics
   - Results page with overview, trending niches, and visualization tabs

2. **Seed-to-Blueprint**:
   - Create channel strategy from a seed video or niche
   - Input for video URL or niche selection with advanced options for analysis depth
   - Results page with tabs for blueprint, competitors, gap analysis, and AI tips

### API Integration

The workflows connect to the SocialIntelligence Agent through proxy handlers:

- `/api/social-intel/niche-scout.ts`
- `/api/social-intel/seed-to-blueprint.ts`
- `/api/social-intel/workflow-history.ts`
- `/api/social-intel/workflow-result/[id].ts`
- `/api/social-intel/scheduled-workflows.ts`
- `/api/social-intel/schedule-workflow.ts`

The implementation includes proper error handling and fallback mock data for development and testing.

## Technology Stack

- **Frontend**: Next.js with React
- **Styling**: TailwindCSS
- **Authentication**: Supabase Auth
- **Real-time Updates**: Supabase Realtime
- **State Management**: React Query and React Context
- **Data Visualization**: Chart.js

## Getting Started

### Prerequisites

- Node.js 16+
- npm or yarn

### Installation

1. Clone the repository
2. Install dependencies:

```bash
cd services/mission-control
npm install
```

3. Set up environment variables:

```
NEXT_PUBLIC_SUPABASE_URL=your-supabase-url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-supabase-anon-key
NEXT_PUBLIC_API_URL=your-api-url
```

4. Run the development server:

```bash
npm run dev
```

5. Open [http://localhost:3000](http://localhost:3000) in your browser

## Project Structure

```
src/
  components/     # Reusable UI components
    layout/       # Page layouts, navigation
    ui/           # Reusable UI components
    metrics/      # Metrics visualization components
    tasks/        # Task management components
    agents/       # Agent visualization components
    auth/         # Authentication components
    workflows/    # Workflow-specific components
  hooks/          # Custom React hooks
  lib/            # Utility functions
  services/       # API service integrations
  pages/          # Next.js pages
  styles/         # Global styles
  types/          # TypeScript type definitions
  contexts/       # React context providers
```

## Deployment

The Mission Control UI is designed to be deployed as a containerized application using Docker. It integrates with the existing Alfred Agent Platform infrastructure.

### Building the Docker Image

```bash
docker build -t mission-control .
```

### Running with Docker Compose

Add the service to the `docker-compose.yml` file:

```yaml
services:
  mission-control:
    image: mission-control
    ports:
      - "3000:3000"
    environment:
      - NEXT_PUBLIC_SUPABASE_URL=your-supabase-url
      - NEXT_PUBLIC_SUPABASE_ANON_KEY=your-supabase-anon-key
      - NEXT_PUBLIC_API_URL=your-api-url
```

## Authentication

The Mission Control UI uses Supabase Auth for authentication and authorization. It supports:

- Email/password authentication
- OAuth providers (Google, GitHub)
- Role-based access control

## Contributing

See the [CONTRIBUTING.md](../../CONTRIBUTING.md) file for details on how to contribute to this project.