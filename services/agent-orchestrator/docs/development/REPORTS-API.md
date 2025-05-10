# Reports API Integration

This document outlines how the Reports feature integrates with backend APIs and services.

## API Endpoints

The Reports feature uses the following API endpoints:

### Get Report List

**Endpoint:** `${API_BASE_URL}/api/reports`  
**Method:** GET  
**Description:** Retrieves a list of available reports

**Response Format:**
```json
{
  "reports": [
    {
      "id": "report-1",
      "title": "Agent Performance Report",
      "description": "Performance metrics for all agents",
      "type": "performance",
      "created_at": "2025-05-06T10:30:00Z",
      "updated_at": "2025-05-06T10:30:00Z"
    },
    {
      "id": "report-2",
      "title": "Workflow Analytics Report",
      "description": "Analytics for workflow executions",
      "type": "workflow",
      "created_at": "2025-05-06T11:15:00Z",
      "updated_at": "2025-05-06T11:15:00Z"
    }
  ]
}
```

### Get Report Data

**Endpoint:** `${API_BASE_URL}/api/reports/${reportId}`  
**Method:** GET  
**Description:** Retrieves data for a specific report

**Parameters:**
- `startDate` (optional): Filter data from this date
- `endDate` (optional): Filter data to this date
- `filter` (optional): Additional filtering options

**Response Format:**
```json
{
  "id": "report-1",
  "title": "Agent Performance Report",
  "description": "Performance metrics for all agents",
  "type": "performance",
  "created_at": "2025-05-06T10:30:00Z",
  "updated_at": "2025-05-06T10:30:00Z",
  "data": {
    "metrics": [
      {
        "agent": "social-intel",
        "success_rate": 98.5,
        "average_response_time": 245,
        "error_count": 3,
        "request_count": 200
      },
      {
        "agent": "financial-tax",
        "success_rate": 99.1,
        "average_response_time": 312,
        "error_count": 1,
        "request_count": 112
      }
    ],
    "timeline": [
      {
        "date": "2025-05-01T00:00:00Z",
        "metrics": {
          "success_rate": 98.2,
          "average_response_time": 260
        }
      },
      {
        "date": "2025-05-02T00:00:00Z",
        "metrics": {
          "success_rate": 98.7,
          "average_response_time": 255
        }
      }
    ]
  }
}
```

### Generate Report

**Endpoint:** `${API_BASE_URL}/api/reports/generate`  
**Method:** POST  
**Description:** Generates a new report

**Request Body:**
```json
{
  "type": "performance",
  "parameters": {
    "startDate": "2025-05-01T00:00:00Z",
    "endDate": "2025-05-06T00:00:00Z",
    "agents": ["social-intel", "financial-tax"],
    "metrics": ["success_rate", "response_time", "error_count"]
  }
}
```

**Response Format:**
```json
{
  "id": "report-3",
  "status": "generating",
  "estimated_completion": "2025-05-06T12:05:00Z"
}
```

## Mock Data Integration

When backend services are unavailable, the Reports feature uses mock data from:

```typescript
// Location: src/data/reports.ts

export const mockReports = [
  // Array of mock report definitions
];

export const mockReportData = {
  // Mock data for each report type
};
```

## Authentication

All report API requests include authentication headers:

```typescript
const headers = {
  "Content-Type": "application/json",
  "Authorization": `Bearer ${token}`
};
```

## Error Handling

The Reports feature implements the following error handling:

1. **API Unavailable:**
   - Falls back to mock data
   - Displays offline indicator
   - Retries connection periodically

2. **Authentication Errors:**
   - Redirects to login page
   - Preserves current report state

3. **Report Not Found:**
   - Shows not found message
   - Provides links to available reports

4. **Report Generation Errors:**
   - Shows detailed error message
   - Offers retry options
   - Logs errors for debugging

## Data Refresh

Reports data is automatically refreshed:

- On initial page load
- Every 5 minutes while viewing
- When filter parameters change
- When manually triggered by refresh button

## Service Integration

### Integration with Social Intelligence Agent

Performance reports pull data from the Social Intelligence Agent metrics endpoint:

```
http://social-intel:9000/api/metrics
```

### Integration with Workflow History

Workflow analytics reports pull data from the workflow history database through:

```
http://social-intel:9000/api/youtube/workflow-history
```

### Integration with System Monitoring

System resource reports pull data from Prometheus metrics:

```
http://prometheus:9090/api/v1/query
```