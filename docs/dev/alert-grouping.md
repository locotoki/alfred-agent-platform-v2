# Alert Grouping Feature

## Overview

The alert grouping feature reduces notification noise by intelligently grouping related alerts based on similarity and temporal proximity.

## Architecture

```mermaid
graph LR
    A[Alert Stream] --> B[Grouping Service]
    B --> C{Similarity Check}
    C -->|Similar| D[Existing Group]
    C -->|Different| E[New Group]
    D --> F[Update Group]
    E --> G[Create Group]
    F --> H[Notification]
    G --> H
```

## Feature Flag Configuration

The alert grouping feature is protected by a feature flag for controlled rollout.

### Environment Variable
```bash
export ALERT_GROUPING_ENABLED=true
```

To check feature flag status in code:
```python
from alfred.alerts.feature_flags import AlertFeatureFlags

if AlertFeatureFlags.is_grouping_enabled():
    # Feature is enabled
    pass
```

## API Usage

### Group Alerts Endpoint

```bash
POST /api/v1/alerts/grouped
Content-Type: application/json
X-Feature-Flag: on  # Required when feature flag is disabled globally

{
  "alerts": [
    {
      "id": "alert-123",
      "name": "HighCPU",
      "severity": "warning",
      "labels": {
        "service": "api-gateway",
        "environment": "prod",
        "region": "us-east-1"
      },
      "timestamp": "2025-05-20T10:00:00Z"
    }
  ],
  "time_window_minutes": 15,
  "similarity_threshold": 0.7
}
```

### Response Format

```json
{
  "groups": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "key": "api-gateway:HighCPU:warning",
      "count": 5,
      "alerts": [
        "alert-123",
        "alert-124"
      ],
      "representative_alert": {
        "id": "alert-123",
        "name": "HighCPU",
        "severity": "warning"
      },
      "last_updated": "2025-05-20T10:15:00Z"
    }
  ]
}
```

**Headers:**
- `X-Feature-Flag: on` - Required when feature flag is disabled globally

## Algorithm Details

The grouping algorithm uses Jaccard similarity to compare alert label sets:

```python
def calculate_similarity(alert1, alert2):
    labels1 = set(alert1.labels.items())
    labels2 = set(alert2.labels.items())
    
    intersection = labels1.intersection(labels2)
    union = labels1.union(labels2)
    
    if not union:
        return 0.0
        
    return len(intersection) / len(union)
```

### Grouping Parameters

- **time_window_minutes**: Maximum time span for alerts in the same group (default: 15)
- **similarity_threshold**: Minimum Jaccard similarity score (default: 0.7)

## UI Component

The UI displays grouped alerts in an accordion with severity badges:

```typescript
<AlertGroupAccordion 
  groups={alertGroups}
  onGroupClick={handleGroupClick}
  showBadges={true}
/>
```

### Component Features
- Collapsible groups with alert counts
- Severity-based color coding
- Representative alert preview
- Time-based sorting

## Performance Monitoring

### Metrics Tracked
- Group calculation latency (P95 < 150ms)
- API response time
- Feature flag check overhead
- Memory usage for large alert sets

### Health Check
```bash
curl http://localhost:8080/health/alert-grouping
```

## Rollout Plan

### Phase 1: Staging (Week 1)
- Deploy with feature flag disabled
- Enable for test accounts
- Monitor performance metrics

### Phase 2: Canary (Week 2)
- Enable for 5% of production traffic
- Compare noise reduction metrics
- Gather user feedback

### Phase 3: General Availability (Week 3)
- Enable globally
- Remove feature flag checks
- Document in user guide

## Troubleshooting

### Common Issues

**No groups returned:**
- Verify feature flag is enabled
- Check similarity threshold (lower if needed)
- Ensure alerts have overlapping time windows

**High latency:**
- Reduce batch size
- Increase similarity threshold
- Check database indexes

**Groups too large:**
- Increase similarity threshold
- Decrease time window
- Add more discriminating labels

### Debug Mode
```bash
export ALERT_GROUPING_DEBUG=true
```

This enables detailed logging of similarity calculations and grouping decisions.

## Future Enhancements

1. Machine learning-based similarity
2. Custom grouping rules per service
3. Alert group lifecycle management
4. Integration with incident management