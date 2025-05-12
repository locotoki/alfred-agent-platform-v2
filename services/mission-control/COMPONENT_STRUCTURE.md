# Mission Control Component Structure

This document provides an overview of the component structure in the Mission Control UI to help with understanding how the UI is organized and where to find specific functionality.

## Directory Structure

```
/src
  /components      # Reusable UI components
    /layout        # Layout components like the main layout and navigation
    /ui            # Basic UI components like buttons, cards, etc.
    /charts        # Chart components for data visualization
    /forms         # Form components and input elements
  /pages           # Next.js pages (file-based routing)
    /api           # API routes for proxying to backend services
    /workflows     # Workflow-specific pages
      /niche-scout # Niche-Scout workflow pages
      /seed-to-blueprint # Seed-to-Blueprint workflow pages
  /services        # Service layer for API calls
  /styles          # Global styles and theme configuration
  /utils           # Utility functions
```

## Key Components

### Layout Components

- `MainLayout.tsx`: The main layout wrapper used by all pages. Includes the sidebar navigation and top bar.
- `Sidebar.tsx`: The main navigation sidebar with links to different sections.
- `TopBar.tsx`: Top navigation bar with user information and actions.

### UI Components

- `StatsCard.tsx`: Used for displaying metrics with icons and trends.
- `LoadingOverlay.tsx`: Loading overlay for long-running operations.
- `Table.tsx`: Base table component used throughout the app.
- `Button.tsx`: Various button styles used in the application.
- `Card.tsx`: Card container used for content sections.

### Workflow Components

- `WorkflowWizard.tsx`: Step-by-step workflow configuration wizard.
- `WorkflowResults.tsx`: Results display for completed workflows.
- `NicheScoutForm.tsx`: Specific form for the Niche-Scout workflow.
- `BlueprintForm.tsx`: Specific form for the Seed-to-Blueprint workflow.

## Page Structure

### Dashboard Page

The dashboard (`/pages/dashboard.tsx`) provides an overview of the system status, including:
- System metrics (CPU, memory, tasks)
- Agent status cards
- Recent activity feed
- Performance metrics

### Workflows Page

The workflows page (`/pages/workflows/index.tsx`) lists available workflows and provides:
- Cards for each workflow type
- Schedule information
- Historical workflow executions

### Workflow Execution Pages

Each workflow has a specific execution page:
- `/pages/workflows/niche-scout/index.tsx`: Niche-Scout workflow configuration
- `/pages/workflows/seed-to-blueprint/index.tsx`: Seed-to-Blueprint workflow configuration

### Results Pages

Workflow results are displayed in dynamic pages:
- `/pages/workflows/niche-scout/results/[id].tsx`: Niche-Scout results
- `/pages/workflows/seed-to-blueprint/results/[id].tsx`: Seed-to-Blueprint results

## API Integration

The API integration is handled through the `/pages/api` folder:

- `/pages/api/social-intel/niche-scout.ts`: Proxy for the Niche-Scout API
- `/pages/api/social-intel/seed-to-blueprint.ts`: Proxy for the Seed-to-Blueprint API
- `/pages/api/social-intel/workflow-history.ts`: Proxy for workflow history
- `/pages/api/social-intel/workflow-result/[id].ts`: Proxy for specific workflow results

These API routes forward requests to the backend services and handle error cases.

## State Management

- React Query is used for data fetching and caching
- Local React state is used for UI state
- No global state management solution is currently implemented

## Styling Approach

- TailwindCSS is used for styling
- A consistent design system is applied across components
- CSS classes follow Tailwind conventions with custom utility classes where needed
- Dark mode support is implemented through Tailwind's dark mode classes