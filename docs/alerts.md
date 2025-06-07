# Alert Runbooks

This document contains runbooks for all Prometheus alerts in the Alfred Agent Platform.

## Cold-Start Alerts

### VectorIngestColdStartTooHigh

**Alert**: `VectorIngestColdStartTooHigh`  
**Severity**: page  
**Threshold**: vector_ingest_cold_start_seconds > 60  
**Duration**: 5 minutes  

#### Description
This alert fires when the vector-ingest service takes longer than 60 seconds to cold-start, which violates our SLA.

#### Impact
- New vector-ingest pods may fail to become ready in time
- Potential cascading failures during scaling events
- Degraded performance for vector embedding operations

#### Investigation Steps
1. Check vector-ingest pod logs:
   ```bash
   kubectl logs -l app=vector-ingest --tail=100
   ```

2. Check resource utilization:
   ```bash
   kubectl top pods -l app=vector-ingest
   ```

3. Review recent deployments:
   ```bash
   kubectl rollout history deployment/vector-ingest
   ```

#### Remediation
1. **Immediate**: Scale up replicas to handle load
   ```bash
   kubectl scale deployment/vector-ingest --replicas=3
   ```

2. **Short-term**: Review and optimize Docker image size
   - Check for unnecessary dependencies
   - Consider multi-stage builds
   - Pre-download ML models in image

3. **Long-term**: Implement warm pool of standby pods

#### Related Issues
- #694 - Nightly bench alert implementation

### ColdStartHigh

**Alert**: `ColdStartHigh`  
**Severity**: warning  
**Threshold**: cold_start_seconds > 60  
**Duration**: 3 minutes  

#### Description
General platform cold-start alert for nightly benchmarks.

#### Investigation Steps
1. Check nightly benchmark results
2. Review recent infrastructure changes
3. Analyze Docker image sizes

#### Remediation
Follow similar steps as VectorIngestColdStartTooHigh but for the entire platform stack.