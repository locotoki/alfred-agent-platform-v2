# Multiple Services Down Runbook

This runbook provides steps to diagnose and resolve issues when multiple services report unhealthy status simultaneously.

## Alert Details

- **Alert Name**: MultipleServicesUnhealthy
- **Severity**: Critical
- **Description**: Multiple services are reporting unhealthy status (service_health = 0)

## Diagnosis Steps

1. **Identify scope of the outage**:
   - Check the health dashboard to see which services are affected
   - Look for patterns (all services in one container? all services using same database?)
   - Check infrastructure health (Docker, host, network)

2. **Examine shared dependencies**:
   - Database connectivity
   - Message queue
   - External APIs
   - Shared network issues
   - Storage/volume issues

3. **Check for global issues**:
   - Host system resource exhaustion (CPU, memory, disk space)
   - Docker daemon issues
   - Network/routing problems
   - DNS resolution problems

## Resolution Steps

1. **Assess critical path**:
   - Focus on user-facing or critical system services first
   - Prioritize services needed for system operations

2. **Check infrastructure**:
   ```bash
   # Check disk space
   df -h
   
   # Check Docker status
   systemctl status docker
   
   # Check memory usage
   free -h
   
   # Check load average
   uptime
   ```

3. **Restart critical services**:
   ```bash
   docker-compose restart <service1> <service2> <service3>
   ```

4. **Verify shared dependencies**:
   - Restart shared databases/caches if needed
   - Check external connectivity
   - Verify Docker network status

5. **Consider full system restart if needed**:
   ```bash
   docker-compose down
   docker-compose up -d
   ```

## Escalation

If multiple services remain down after following the steps above, escalate to:

1. On-call DevOps engineer and SRE team
2. Platform team lead
3. Engineering leadership if major production outage

## Post-Resolution

1. Document the incident in the incident log
2. Create a post-mortem for review
3. Create tickets for any follow-up work needed
4. Review and update monitoring or alerting rules
5. Consider implementing additional resilience measures

## Related Resources

- [System Architecture Diagram](../architecture/system-architecture.md)
- [Infrastructure Recovery Guide](../operations/disaster-recovery/infrastructure-recovery.md)
- [Monitoring Dashboard](https://grafana.example.com/d/platform/health-dashboard)