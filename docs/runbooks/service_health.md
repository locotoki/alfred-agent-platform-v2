# Service Health Runbook

This runbook provides steps to diagnose and resolve issues when a service reports unhealthy status.

## Alert Details

- **Alert Name**: ServiceUnhealthy
- **Severity**: Critical
- **Description**: A service is reporting an unhealthy status (service_health = 0)

## Diagnosis Steps

1. **Check the affected service**:
   - Identify which service is unhealthy from the alert
   - Check the service logs: `docker logs <service-container-name>`
   - Check resource usage: `docker stats <service-container-name>`

2. **Check dependent services**:
   - Verify database connectivity if applicable
   - Check message queue status if used
   - Verify external API dependencies

3. **Check for recent changes**:
   - Was there a recent deployment?
   - Were configuration changes made?
   - Check git history for recent commits affecting the service

## Resolution Steps

1. **Restart the service**:
   ```bash
   docker-compose restart <service-name>
   ```

2. **Verify the service health endpoint**:
   ```bash
   curl http://<service-host>:<service-port>/health
   ```

3. **Check logs for specific errors**:
   ```bash
   docker logs --tail=100 <service-container-name>
   ```

4. **Restore from a known good state**:
   - Roll back to the previous version if a recent deployment caused the issue
   - Restore configuration from backup if needed

5. **Scale up/down if needed**:
   ```bash
   docker-compose up -d --scale <service-name>=2
   ```

## Escalation

If the issue persists after following the steps above, escalate to:

1. On-call DevOps engineer
2. Service owner (check CODEOWNERS file)
3. Platform team lead

## Post-Resolution

1. Document the incident in the incident log
2. Create a post-mortem if this was a major outage
3. Create tickets for any follow-up work needed
4. Update monitoring or alerting rules if needed

## Related Resources

- [Service Architecture Diagram](../architecture/service-architecture.md)
- [Deployment Guide](../operations/deployment.md)
- [Monitoring Dashboard](https://grafana.example.com/d/platform/health-dashboard)