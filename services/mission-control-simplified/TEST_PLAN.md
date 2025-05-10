# Social Intelligence Integration Test Plan

This document outlines the test procedures for verifying the integration between Simplified Mission Control and the Social Intelligence Agent.

## Prerequisites

- Social Intelligence Agent running and accessible
- Node.js and npm installed
- Docker installed (for container testing)

## Test Matrix

| Component | Test Type | Description | Expected Result |
|-----------|-----------|-------------|----------------|
| Health API | Unit | Check health endpoint | Returns healthy status with service info |
| Agents API | Integration | Fetch agent statuses | Returns all agent statuses |
| Niche-Scout | Functional | Execute workflow | Returns trending niches data |
| Seed-to-Blueprint | Functional | Execute workflow | Returns channel blueprint |
| Fallback | Resilience | Simulate agent unavailable | Falls back to mock data |
| Container | Deployment | Run in Docker | Container starts and APIs work |

## Test Procedures

### 1. Health API Test

```bash
curl http://localhost:3007/api/health
```

Expected: JSON response with "healthy" status and services list.

### 2. Agents API Test

```bash
curl http://localhost:3007/api/agents/status
```

Expected: JSON response with array of agent statuses.

### 3. Niche-Scout Workflow Test

```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{"category":"gaming","subcategory":"mobile-gaming"}' \
  http://localhost:3007/api/workflows/niche-scout
```

Expected: JSON response with trending niches data.

### 4. Seed-to-Blueprint Workflow Test

```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{"input_type":"video","video_url":"https://www.youtube.com/watch?v=example"}' \
  http://localhost:3007/api/workflows/seed-to-blueprint
```

Expected: JSON response with channel blueprint data.

### 5. Fallback Test

1. Stop the Social Intelligence Agent
2. Run the Niche-Scout and Seed-to-Blueprint tests again
3. Verify mock data is returned

### 6. Container Test

```bash
docker-compose up -d
curl http://localhost:3007/api/health
```

Expected: Container starts and health endpoint returns healthy status.

## Validation Criteria

- All API endpoints return expected data structures
- Error handling works correctly
- Fallback to mock data functions when agent is unavailable
- Container deployment works with proper networking

## Automated Testing

The integration includes automated test scripts to verify functionality:

### Integration Tests

The `tests/test-integration.js` script performs end-to-end testing of all API endpoints:

```bash
npm test
```

### Direct API Tests

The `tests/test-social-intel-direct.js` script tests direct connectivity to the Social Intelligence Agent:

```bash
npm run test:social-intel
```

## UI Testing

In addition to API testing, perform the following UI tests:

1. Access the Dashboard at http://localhost:3007/
   - Verify agent statuses are displayed correctly
   - Check that system metrics are shown

2. Access the Niche-Scout workflow at http://localhost:3007/workflows/niche-scout
   - Complete the 3-step wizard
   - Verify results are displayed correctly

3. Access the Seed-to-Blueprint workflow at http://localhost:3007/workflows/seed-to-blueprint
   - Complete the 3-step wizard
   - Verify channel blueprint is displayed correctly

## Regression Testing

After making any changes to the integration:

1. Run all automated tests
2. Perform manual API tests
3. Verify UI functionality
4. Test container deployment

## Test Environment Setup

To prepare the test environment:

```bash
# Install dependencies
npm install

# Start the server
node server.js

# In a separate terminal
npm test
```

When testing with Docker:

```bash
# Build and start the container
docker-compose up -d --build

# Run API tests
curl http://localhost:3007/api/health
```