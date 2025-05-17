# 6-Hour Staging Soak Plan for v0.8.1-rc1

## Schedule
- **T0**: 2025-05-15 22:00 UTC - Initial quick-proof checks ✅
- **T+3h**: 2025-05-16 01:00 UTC - First checkpoint
- **T+6h**: 2025-05-16 04:00 UTC - Final checkpoint & GA decision

## Metrics to Monitor at Each Checkpoint

| Metric / Signal | Normal Range (Staging) | Escalate If | Status at T0 |
|-----------------|------------------------|-------------|--------------|
| `db_connection_errors_total{job="db-metrics"}` | 0 | > 0 for any instance | 0 ✅ |
| `alfred_query_latency_seconds{quantile="0.95"}` | ≤ 120 ms | > 300 ms for ≥ 2 samples | N/A (no queries yet) |
| `process_resident_memory_bytes` (DB-metrics pod) | < 200 MiB | > 300 MiB for 10 min | All < 50 MiB ✅ |
| `scrape_duration_seconds{job="db-metrics"}` P95 | < 1 s | > 2 s | All < 10ms ✅ |
| `scrape_samples_post_metric_relabeling` | ~500-800 | Sudden drop > 25% or spike > 50% | 20 samples per instance ✅ |
| K8s restarts | 0 | ≥ 1 restart in any db-metrics pod | 0 ✅ |
| Alertmanager | None firing | Any alert in DB Metrics group | None ✅ |
| Extra: `histogram_quantile(0.90, sum(rate(scrape_duration_seconds_bucket[5m])) by (le))` | ≲ 0.4 s | > 1 s | N/A (insufficient data) |

## T+6h Decision Tree

### If All Metrics Pass:
1. Run `./scripts/promote-to-ga.sh` to tag v0.8.1 GA
2. Update CHANGELOG.md and commit with message "docs: v0.8.1 GA"
3. Push changes
4. Close issue #db-metrics-canary with "GA promoted"
5. Create Phase 8 tracking issue for future enhancements

### If Any Threshold Breached:
1. Run `./scripts/rollback-canary.sh`
2. Label issue as canary-fail
3. Ping Architect for further investigation

## Phase 8 Enhancement Tracking (Future)
1. `db_connection_errors_total` alert rule
2. Latency SLOs
3. Autoscaling based on error rate