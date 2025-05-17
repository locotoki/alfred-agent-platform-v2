# Alfred Core Health Critical

## Overview
This alert indicates that the Alfred Core service is down and not responding to health checks.

## Impact
- Core API functionality unavailable
- Dependent services may experience errors
- User requests will fail

## Investigation Steps

1. Check pod status:
   ```bash
   kubectl get pods -l app=alfred-core
   kubectl describe pod <pod-name>
   ```

2. Check recent logs:
   ```bash
   kubectl logs -l app=alfred-core --tail=100
   ```

3. Check resource usage:
   ```bash
   kubectl top pod -l app=alfred-core
   ```

4. Verify configuration:
   ```bash
   kubectl get configmap alfred-core-config -o yaml
   ```

## Resolution

### Quick Fix
1. Restart the pod:
   ```bash
   kubectl delete pod -l app=alfred-core
   ```

2. Scale up if needed:
   ```bash
   kubectl scale deployment alfred-core --replicas=3
   ```

### Root Cause Analysis
- Check for recent deployments
- Review configuration changes
- Examine dependency health
- Check for resource constraints

## Escalation
- If issue persists > 15 minutes: Page on-call engineer
- If data corruption suspected: Page database team
- For configuration issues: Contact platform team

## Prevention
- Implement circuit breakers
- Add retry logic with backoff
- Monitor resource trends
- Regular load testing

## Related Links
- [Alfred Core Architecture](../docs/architecture/alfred-core.md)
- [Deployment Guide](../docs/deployment-guide.md)
- [Monitoring Dashboard](https://grafana.example.com/d/alfred-core)
