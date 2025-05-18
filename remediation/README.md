# Remediation System

The Remediation System provides automated service recovery capabilities for the Alfred Agent Platform using LangGraph for workflow orchestration.

## Overview

This package contains LangGraph-based remediation workflows that can:

1. Automatically restart failing services
2. Wait for service stabilization
3. Verify health after restarts
4. Retry with configurable attempts
5. Escalate to on-call team when necessary

## Architecture

The remediation system is designed around a graph-based workflow:

```
┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐
│ Restart │────>│  Wait   │────>│  Probe  │────>│Complete │
└─────────┘     └─────────┘     └─────────┘     └─────────┘
     ▲                               │
     │                               │
     └───────────────────────────────┘
                    │
                    ▼
              ┌─────────┐
              │Escalate │
              └─────────┘
```

## Usage

```python
from remediation.graphs import restart_then_verify

# Create a remediation graph for a specific service
graph, initial_state = restart_then_verify(
    service_name="model-router",
    wait_seconds=30,
    max_retries=3
)

# Execute the remediation
result = graph.invoke(initial_state)

# Check the result
if result["remediation_status"] == "success":
    print(f"Service {result['service_name']} successfully remediated")
else:
    print(f"Service {result['service_name']} failed remediation, escalated to on-call")
```

## Integration with Slack

The remediation system can be triggered from Slack using the `/alfred remediate <service>` command and provides real-time updates in the Slack thread.

## Monitoring and Metrics

The remediation system exports Prometheus metrics for:
- Remediation attempts
- Success/failure rates
- Time-to-recovery

## Extending

To add new remediation strategies:
1. Create new node functions in `graphs.py`
2. Define new graph structures that connect these nodes
3. Add appropriate tests to ensure coverage

## Future Plans

- Exponential backoff between retries
- Multi-service dependency-aware remediation
- ML-based predictive recovery strategies
- Integration with alert management systems
