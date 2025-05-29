# p95 Latency Alert

> **Status:** Ready
> **Linked issue:** #576

## Purpose
Guide on-call engineers through diagnosing and mitigating p95 latency alerts emitted by Prometheus rule `api_gateway_p95_latency_seconds > 1.2`.

## Prerequisites
- Grafana & Loki access
- `kubectl` access to `gateway` namespace
- Slack pager permissions

## Procedure
1. **Acknowledge alert** in Slack `#ops-alerts`.

2. **Initial assessment**
   - Grafana → dashboard `Gateway Latency` → confirm spike pattern.
   - Check request volume and error rate.

3. **Identify culprit service**
   ```bash
   kubectl -n gateway logs -l app=api-gateway --since=5m | \
     grep "upstream_time" | sort -nr -k2 | head
   ```

4. **Common remediations**
   | Cause | Fix |
   |-------|-----|
   | DB slow query | Enable `pg_stat_statements`; add index |
   | Cache miss surge | Scale Redis/enable Redis Cluster |
   | CPU throttling | `kubectl scale deploy api-gateway --replicas=+2` |

5. **Post-incident tasks**
   - Raise follow-up ticket if root cause requires code change.
   - Add Prometheus SLO annotation if threshold needs tuning.

## Validation
Alert resets in Prometheus; p95 in Grafana returns to baseline (< 1.0 s) for 30 min.

## Rollback
Undo scaling or config overrides; monitor for regression.
