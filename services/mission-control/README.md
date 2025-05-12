# Alfred Agent Platform - Mission Control UI

Mission Control is the centralized dashboard for monitoring and managing the Alfred Agent Platform. It provides a business-oriented view of the platform's metrics, agent status, and task management capabilities.

## Features

- 📊 **Dashboard**: Real-time overview of platform health, agent status, and recent activity
- 🤖 **Agent Management**: Monitor and control individual agents in the platform
- 📝 **Task Management**: Create, monitor, and manage tasks across agents
- 🔄 **Workflow Hub**: Run and schedule specialized workflows like YouTube research tools
- 📈 **Reporting**: View and export reports on platform performance

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

- **Frontend**: Next.js 14.x with React 18
- **Language**: TypeScript
- **Styling**: TailwindCSS
- **Data Fetching**: React Query
- **Animations**: Framer Motion
- **Charts**: Chart.js with React-Chartjs-2
- **Authentication**: Supabase Auth

## Getting Started

### Prerequisites

- Node.js 18+
- npm or yarn
- Docker (for running with backend services)

### Local Development

1. Install dependencies:
   ```bash
   npm install
   ```

2. Create a `.env.local` file with required environment variables:
   ```
   NEXT_PUBLIC_SOCIAL_INTEL_URL=http://localhost:9000
   NEXT_PUBLIC_SUPABASE_URL=your-supabase-url
   NEXT_PUBLIC_SUPABASE_ANON_KEY=your-supabase-anon-key
   ```

3. Start the development server:
   ```bash
   npm run dev
   ```

4. Access the UI at http://localhost:3007

### Docker Development

1. Build the Docker image:
   ```bash
   docker build -t alfred-mission-control -f Dockerfile.dev .
   ```

2. Run the container:
   ```bash
   docker run -p 3007:3000 -e NEXT_PUBLIC_SOCIAL_INTEL_URL=http://social-intel:9000 alfred-mission-control
   ```

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
    api/          # API routes for proxying to backend services
    workflows/    # Workflow-specific pages
  styles/         # Global styles
  types/          # TypeScript type definitions
  contexts/       # React context providers
```

## Documentation

- [Component Structure](./COMPONENT_STRUCTURE.md) - Detailed overview of UI components
- [API Integration](./API_INTEGRATION.md) - Guide to backend service integration
- [Workflow Guide](./WORKFLOW_GUIDE.md) - Patterns for workflow implementation
- [Design Brief](./lovable-dev-prompt.md) - Design requirements for lovable.dev

## Design Goals

The UI is designed with the following principles:

1. **Simplicity First**: Focus on essential functionality
2. **Task-Oriented**: Organize UI around user tasks, not system architecture
3. **Feedback & Transparency**: Clear status indicators and meaningful error messages
4. **Progressive Disclosure**: Show only what's needed at each step

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
      - "3007:3000"
    environment:
      - NEXT_PUBLIC_SUPABASE_URL=your-supabase-url
      - NEXT_PUBLIC_SUPABASE_ANON_KEY=your-supabase-anon-key
      - NEXT_PUBLIC_SOCIAL_INTEL_URL=http://social-intel:9000
```

## Authentication

The Mission Control UI uses Supabase Auth for authentication and authorization. It supports:

- Email/password authentication
- OAuth providers (Google, GitHub)
- Role-based access control

## Contributing

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## License

MIT License