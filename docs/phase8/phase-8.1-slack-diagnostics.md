# Phase 8.1 - Slack Diagnostics Bot Implementation

## Overview
The Slack Diagnostics Bot provides real-time system health and metrics visibility through Slack commands.

## Implementation Details

### Module: `alfred.slack.diagnostics`

**Class**: `DiagnosticsBot`

The bot responds to slash commands in Slack:
- `/diag health` - Checks health status of all Alfred services
- `/diag metrics` - Queries Prometheus for key system metrics

### Configuration

Helm values:
```yaml
slack:
  enabled: false
  diagnostics:
    enabled: false
    commands:
      health: "/diag health"
      metrics: "/diag metrics"
  prometheus:
    url: "http://prometheus:9090"
```

### Health Command

Checks the following services:
- alfred-core
- mission-control  
- social-intel
- model-registry
- model-router

Response format:
```
🏥 Service Health Status
✅ alfred-core: healthy
✅ mission-control: healthy
❌ social-intel: Connection refused
```

### Metrics Command

Queries Prometheus for:
- Request Rate (req/s)
- Error Rate (errors/s)
- P95 Latency (ms)
- Active Agents count

Response format:
```
📊 System Metrics
Request Rate: 42.50 req/s
Error Rate: 0.12 req/s
P95 Latency: 125.34 ms
Active Agents: 3
```

## Testing

Unit tests included:
- Disabled bot behavior
- Unknown command handling
- Command error handling
- Health check success/failure
- Metrics query success/no data

```bash
pytest alfred/slack/tests/test_diagnostics.py -v
```

## Usage

1. Enable in Helm values (staging/prod)
2. Configure Slack webhook URL
3. Register slash commands in Slack app
4. Deploy to cluster

## Security

- Bot can be disabled via Helm
- No sensitive data exposed
- Read-only operations
- Structured logging with context