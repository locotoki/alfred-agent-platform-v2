# Alfred Agent Orchestrator Architecture

## System Architecture

The Alfred Agent Orchestrator is implemented as part of a microservices architecture within the Alfred Agent Platform. Here's how it relates to other containers and services:

```
                     ┌───────────────────┐
                     │      User         │
                     │    Interface      │
                     └─────────┬─────────┘
                               │
                               ▼
┌───────────────────────────────────────────────────┐
│                Agent Orchestrator                 │
│                                                   │
│  ┌─────────────┐  ┌────────────┐  ┌────────────┐  │
│  │  Workflows  │  │  Reports   │  │   Agent    │  │
│  │  Management │  │  Dashboard │  │  Control   │  │
│  └─────────────┘  └────────────┘  └────────────┘  │
└───────────┬───────────────┬───────────────┬───────┘
            │               │               │
┌───────────▼───────┐ ┌─────▼───────┐ ┌─────▼───────┐
│ Social Intelligence│ │ Financial Tax│ │    Legal    │
│      Agent        │ │    Agent     │ │  Compliance │
└───────────┬───────┘ └─────────────┘ └─────────────┘
            │
┌───────────▼───────┐
│   Alfred Bot      │
│    Agent          │
└───────────────────┘
```

## Network Configuration

The Alfred Agent Orchestrator container is connected to the `alfred-network` Docker network along with all other service containers. This enables direct communication between services using container names as hostnames.

### Current Network Configuration:

- **agent-orchestrator**: 172.18.0.20
- **social-intel**: 172.18.0.10
- **alfred-bot**: 172.18.0.13
- **financial-tax**: 172.18.0.12
- **legal-compliance**: 172.18.0.11

## Service Interactions

The orchestrator interacts with other services as follows:

### 1. Social Intelligence Agent

- **Primary Interface**: REST API
- **Connection**: http://social-intel:9000/api/*
- **Functionality**: 
  - YouTube workflow execution (Niche-Scout, Seed-to-Blueprint)
  - Workflow history and results retrieval
  - Scheduled workflow management

### 2. Financial Tax Agent

- **Primary Interface**: REST API
- **Connection**: http://financial-tax:9003/api/*
- **Functionality**:
  - Tax analysis workflow execution
  - Financial report generation
  - Compliance check operations

### 3. Legal Compliance Agent

- **Primary Interface**: REST API
- **Connection**: http://legal-compliance:9002/api/*
- **Functionality**:
  - Legal document analysis
  - Compliance verification
  - Regulatory check operations

### 4. Alfred Bot Agent

- **Primary Interface**: REST API
- **Connection**: http://alfred-bot:8011/api/*
- **Functionality**:
  - Central coordination
  - Cross-agent workflow orchestration
  - System-wide status monitoring

## Database Integration

The orchestrator connects to the database through the Supabase services:

- **PostgREST**: http://supabase-rest:3000
- **Authentication**: http://supabase-auth:9999
- **Storage**: http://supabase-storage:5000

## Monitoring Integration

The orchestrator retrieves monitoring data from:

- **Prometheus**: http://prometheus:9090/api/v1/query
- **Grafana**: http://grafana:3000/api/dashboards

## Deployment Model

The Alfred Agent Orchestrator is designed as a lightweight, stateless UI container that:

1. Serves the React frontend application
2. Makes API calls to various agent services
3. Visualizes results and system status
4. Provides user controls for agent operations

## Authentication Flow

1. User authentication is handled through Supabase Auth
2. The orchestrator receives a JWT token
3. All subsequent API calls include this token
4. Agent services validate tokens with Supabase Auth

## Data Flow

```
User Request -> Orchestrator UI -> Agent API -> Agent Processing -> Database
                     ↑                                 |
                     └─────────────────────────────────┘
                               Results
```

## Scaling Considerations

The orchestrator is designed to scale horizontally:

- Multiple instances can be deployed behind a load balancer
- Each instance is stateless and relies on backend services for state
- Session persistence is handled through Supabase Auth

## Container Configuration

The orchestrator container uses the following configuration:

- **Base Image**: Node 20 Alpine
- **Exposed Port**: 8080
- **Volume Mounts**: Source code for development mode
- **Environment Variables**: API URLs and feature flags
- **Health Check**: HTTP request to root path