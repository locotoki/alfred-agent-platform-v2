# API Integration Guide

This document explains how the Mission Control UI integrates with backend services and provides information needed for lovable.dev to ensure proper API functionality is maintained.

## API Architecture

The Mission Control UI interacts with backend services via proxy API routes defined in the `/pages/api` directory. This architecture decouples the frontend from direct backend dependencies and allows for:

1. Consistent error handling
2. Request/response transformation
3. Authentication handling
4. Mock data for development and testing

## Key Backend Services

### Social Intelligence Service

The primary service for YouTube workflow functionality:

- Base URL: `http://social-intel:9000` (in development environment)
- Available endpoints:
  - `/niche-scout`: Niche Scout workflow
  - `/seed-to-blueprint`: Seed-to-Blueprint workflow
  - `/workflow-history`: Get workflow execution history
  - `/workflow-result/{id}`: Get specific workflow results
  - `/schedule-workflow`: Schedule a workflow for later execution
  - `/scheduled-workflows`: Get list of scheduled workflows

## API Proxy Implementation

### Request Format

The Social Intelligence service expects requests in the A2A (Agent-to-Agent) envelope format:

```typescript
interface A2AEnvelope {
  intent: string; // e.g., "YOUTUBE_NICHE_SCOUT"
  data: {
    // Intent-specific payload
    [key: string]: any;
  };
  task_id: string;
  trace_id: string;
}
```

Example for Niche-Scout:
```typescript
const payload = {
  intent: 'YOUTUBE_NICHE_SCOUT',
  data: {
    queries: [query],
    category: category || 'All',
    timeRange: timeRange || 'Last 30 days',
    demographics: demographics || 'All'
  },
  task_id: `niche-scout-${Date.now()}`,
  trace_id: `trace-${Date.now()}`
};
```

### Response Format

The Social Intelligence service responds with workflow-specific data:

For Niche-Scout:
```typescript
interface NicheScoutResult {
  run_date: string;
  trending_niches: Array<{
    query: string;
    view_sum: number;
    rsv: number;
    view_rank: number;
    rsv_rank: number;
    score: number;
    x: number;
    y: number;
    niche: number;
  }>;
  top_niches: Array<{/* same as trending_niches */}>;
  visualization_url: string;
  actual_cost: number;
  actual_processing_time: number;
  _files: {
    json_report: string;
    report_file: string;
  };
  _id: string;
}
```

For Seed-to-Blueprint:
```typescript
interface BlueprintResult {
  channel_strategy: {
    title: string;
    description: string;
    niche: string;
    target_audience: Array<string>;
    content_pillars: Array<string>;
    video_formats: Array<{
      format: string;
      frequency: string;
      length: string;
    }>;
    content_schedule: Array<{
      day: number;
      title: string;
      description: string;
      pillar: string;
      format: string;
      keywords: Array<string>;
    }>;
  };
  competitor_analysis: Array<{
    channel_name: string;
    subscribers: number;
    avg_views: number;
    top_videos: Array<{
      title: string;
      views: number;
      published: string;
    }>;
    content_focus: Array<string>;
  }>;
  _id: string;
  _files: {
    json_report: string;
    report_file: string;
  };
}
```

### Error Handling

The API proxies implement error handling to provide graceful degradation:

1. Service unavailable: Return mock data with `_mock: true` flag
2. Service error: Return appropriate error information
3. Network timeout: Implement retry logic with exponential backoff

Example error handling pattern:
```typescript
try {
  // API call logic
} catch (error) {
  console.error('API error:', error);
  
  if (useMockData(error)) {
    const mockData = getMockNicheScoutData();
    mockData._mock = true;
    mockData._mockReason = 'API call failed';
    mockData._mockTimestamp = new Date().toISOString();
    return res.status(200).json(mockData);
  }
  
  return res.status(500).json({ 
    error: 'Failed to run workflow',
    message: error instanceof Error ? error.message : 'Unknown error',
    _id: `error-${Date.now()}`
  });
}
```

## Mock Data

For development and testing purposes, mock data implementations are provided:

- `/pages/api/social-intel/proxy-helper.ts`: Contains mock data generation functions
- Each workflow has specific mock data with realistic values

## Authentication

The API uses Supabase for authentication:

- JWT tokens are used for authentication
- API routes should verify authentication before proxying requests
- The current implementation is minimal and should be enhanced

## Integration Best Practices

When maintaining or extending the API integration:

1. Always validate request data before sending to backend
2. Include comprehensive error handling
3. Provide mock data for development and testing
4. Log meaningful information for debugging
5. Use types for request/response data
6. Maintain the A2A envelope format for compatibility
7. Add appropriate timeout handling for long-running operations