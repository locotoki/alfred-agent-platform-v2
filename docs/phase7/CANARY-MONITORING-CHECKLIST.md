# Canary Monitoring Checklist for v0.7.0-rc2

## Purpose
This checklist outlines what needs to be monitored during the 24-hour canary period for the v0.7.0-rc2 release, which includes the LangGraph remediation engine.

## Monitoring Items

### Slack Integration
- [ ] Verify that `/alfred health` command works correctly
- [ ] Verify that `/alfred remediate <service>` command triggers remediation workflow
- [ ] Confirm that escalation messages include probe_error field when errors occur
- [ ] Check format and clarity of error messages in Slack

### LangGraph Remediation
- [ ] Verify that remediation graphs execute properly for different services
- [ ] Confirm retry logic works as expected (max retries from environment settings)
- [ ] Verify that error details from probes are correctly included in logs
- [ ] Check that escalated issues include detailed error information

### Metrics & Monitoring
- [ ] Verify that remediation attempts are properly logged in Prometheus
- [ ] Check Grafana dashboards for remediation success/failure rates
- [ ] Monitor error rates and latency for health probes
- [ ] Verify that remediation events are traced with OpenTelemetry

### Performance
- [ ] Monitor resource usage of the remediation system
- [ ] Check latency of remediation operations
- [ ] Verify that wait times are correctly observed

## How to Check Escalation Messages

1. Trigger a failing remediation:
   ```bash
   # Manually stop a service to force a failure
   docker stop alfred-agent-platform-v2_model-router_1

   # Trigger remediation via Slack
   /alfred remediate model-router
   ```

2. Let the remediation process attempt MAX_RETRIES times

3. Verify the escalation message in Slack includes:
   - Number of attempts/max retries
   - Service name
   - Last error message from probe_error field
   - Link to logs/dashboard

4. Check logs for complete error information:
   ```bash
   # Check container logs
   docker logs alfred-agent-platform-v2_alfred-core_1 | grep 'Escalating remediation'
   ```

## Contact Information

If issues are detected during the canary period, contact:
- Primary: DevOps Team Lead
- Secondary: Platform Engineering Team

## Success Criteria for Promotion to Production

- No increase in error rates during the 24-hour period
- All monitoring items verified and passing
- Slack integration functioning correctly with proper error details
- At least 5 successful remediations performed
- All escalation messages properly formatted with error details
