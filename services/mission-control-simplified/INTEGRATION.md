# Social Intelligence Integration Guide

This document provides detailed instructions for integrating the Simplified Mission Control with the Social Intelligence Agent.

## Overview

The integration allows Simplified Mission Control to:

1. Execute Niche-Scout workflows using the Social Intelligence Agent
2. Execute Seed-to-Blueprint workflows using the Social Intelligence Agent
3. Monitor the status of all platform agents
4. Provide graceful fallback to mock data when needed

## Configuration

### Environment Variables

The integration is configured through environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `SOCIAL_INTEL_HOST` | Hostname or IP address of the Social Intelligence Agent | `http://localhost` |
| `SOCIAL_INTEL_PORT` | Port number for the Social Intelligence Agent | `9000` |
| `ENABLE_MOCK_FALLBACK` | Whether to fall back to mock data when API calls fail | `true` |
| `API_TIMEOUT` | Timeout for API calls in milliseconds | `5000` |

### Setup Files

Two environment files are provided:
- `.env` - For local development
- `.env.docker` - For Docker container deployment

## API Endpoints

### Health Check
```
GET /api/health
```

Response:
```json
{
  "status": "healthy",
  "uptime": 123.45,
  "services": {
    "social-intelligence": "online"
  },
  "timestamp": "2023-05-08T12:34:56.789Z"
}
```

### Agent Status
```
GET /api/agents/status
```

Response:
```json
{
  "agents": [
    {
      "name": "Social Intelligence",
      "status": "online",
      "cpu": 38,
      "memory": 512,
      "tasks": 3
    },
    ...
  ]
}
```

### Niche-Scout Workflow
```
POST /api/workflows/niche-scout
```

Request:
```json
{
  "category": "gaming",
  "subcategory": "mobile-gaming"
}
```

Response:
```json
{
  "id": "wf-1234567890",
  "status": "completed",
  "result": {
    "trending_niches": [
      {
        "name": "Mobile Gaming",
        "growth": 32,
        "views": 3200000,
        "score": 85
      },
      ...
    ]
  }
}
```

### Seed-to-Blueprint Workflow
```
POST /api/workflows/seed-to-blueprint
```

Request:
```json
{
  "input_type": "video",
  "video_url": "https://www.youtube.com/watch?v=example"
}
```

Response:
```json
{
  "id": "wf-1234567890",
  "status": "completed",
  "result": {
    "channel_blueprint": {
      "focus": "programming tutorials and coding guides",
      "audience_potential": 4200000,
      "growth_score": 82,
      "competition_score": 76,
      ...
    }
  }
}
```

## Testing

### Test Scripts

Two test scripts are provided:

1. `tests/test-integration.js` - Tests the Mission Control API endpoints
2. `tests/test-social-intel-direct.js` - Tests direct connectivity to the Social Intelligence Agent

Run tests with:
```bash
# Test Mission Control integration
npm test

# Test direct connection to Social Intelligence Agent
npm run test:social-intel
```

### Manual Testing

You can manually test the API endpoints with curl:

```bash
# Health check
curl http://localhost:3007/api/health

# Agent status
curl http://localhost:3007/api/agents/status

# Niche-Scout workflow
curl -X POST -H "Content-Type: application/json" \
  -d '{"category":"gaming","subcategory":"mobile-gaming"}' \
  http://localhost:3007/api/workflows/niche-scout

# Seed-to-Blueprint workflow
curl -X POST -H "Content-Type: application/json" \
  -d '{"input_type":"video","video_url":"https://www.youtube.com/watch?v=example"}' \
  http://localhost:3007/api/workflows/seed-to-blueprint
```

## Troubleshooting

### Connection Issues

If you're having trouble connecting to the Social Intelligence Agent:

1. Check if the agent is running: `docker ps | grep social-intel`
2. Verify network connectivity: `docker exec mission-control-simplified ping social-intel`
3. Check if the correct ports are exposed: `docker port social-intel`
4. Check logs for errors: `docker logs social-intel`

### API Errors

If API calls are failing:

1. Check the Mission Control logs: `docker logs mission-control-simplified`
2. Ensure the Social Intelligence API endpoints match the expected format
3. Verify environment variables are correctly set
4. Try direct API calls using curl from inside the container:
   ```bash
   docker exec mission-control-simplified curl social-intel:9000/status
   ```

## Implementation Details

The integration is implemented through these key files:

1. `integrate-with-social-intel.js` - Core integration logic
2. `server.js` - Express server that uses the integration
3. `.env` and `.env.docker` - Configuration files

The integration uses a fallback mechanism to provide mock data when the Social Intelligence Agent is unavailable, ensuring the UI remains functional even during outages.

## Social Intelligence Agent API Endpoints

The following endpoints are used by the integration:

| Endpoint | Description | Method | Status |
|----------|-------------|--------|--------|
| `/status` | Check agent status | GET | ✅ Working |
| `/api/youtube/niche-scout` | Execute Niche-Scout workflow | POST | ✅ Working |
| `/api/youtube/blueprint` | Execute Seed-to-Blueprint workflow | POST | ❌ Not Implemented Yet |

### API Response Formats

#### Niche-Scout Response Format

The Niche-Scout API returns data in the following format:

```json
{
  "date": "2025-05-08",
  "query": "gaming",
  "category": "Gaming",
  "niches": [
    {
      "name": "Financial Literacy Shorts",
      "growth_rate": 87.5,
      "shorts_friendly": true,
      "competition_level": "Medium",
      "viewer_demographics": {
        "age_groups": ["18-24", "25-34"],
        "gender_split": {"male": 65, "female": 35}
      },
      "trending_topics": [
        "Stock market tips",
        "Passive income ideas",
        "Investing for beginners"
      ]
    },
    // More niches...
  ],
  "analysis_summary": {
    "fastest_growing": "Financial Literacy Shorts",
    "most_shorts_friendly": "Financial Literacy Shorts",
    "lowest_competition": "Financial Literacy Shorts"
  }
}
```

#### Seed-to-Blueprint Response Format

The Seed-to-Blueprint API is not yet implemented in the Social Intelligence Agent, so the integration falls back to mock data with this format:

```json
{
  "id": "wf-1234567890",
  "status": "completed",
  "result": {
    "channel_blueprint": {
      "focus": "programming tutorials and coding guides",
      "audience_potential": 4200000,
      "growth_score": 82,
      "competition_score": 76,
      "video_ideas_count": 24,
      "content_pillars": [
        "Web Development Fundamentals",
        "Framework Tutorials",
        "Backend Development",
        "Database Integration",
        "Deployment and DevOps"
      ],
      "trending_topics": [
        "Serverless Functions",
        "Web Assembly",
        "State Management",
        "TypeScript Migration",
        "API Security"
      ]
    }
  }
}
```

## Fallback Mechanism

The integration includes a robust fallback mechanism that:

1. Attempts to call the real API endpoint
2. Catches any errors that occur
3. Returns mock data if `ENABLE_MOCK_FALLBACK` is true
4. Throws the error if `ENABLE_MOCK_FALLBACK` is false

This ensures that the UI remains functional even when the Social Intelligence Agent is unavailable, while still providing accurate error messages for debugging.