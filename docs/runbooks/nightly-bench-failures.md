# Nightly Bench Failures

> **Status:** Ready  
> **Linked issue:** #575  

## Purpose
Systematically triage and resolve failures in the nightly benchmark GitHub Actions workflow to maintain the ≤ 75 s SLA.

## Prerequisites
- Write access to repository workflows  
- Ability to run stack locally with `alfred bench`  
- Access to Grafana dashboard `Bench – cold-start`  

## Procedure
1. **Detect failure**  
   GitHub notification → open workflow run → identify failing step.

2. **Collect artefacts & logs**  
   Download benchmark artefacts; inspect `bench.log` and container logs.

3. **Reproduce locally**  
   ```bash
   alfred up --profile core,bizdev --bench
   ./scripts/run-bench.sh
   ```

4. **Classify issue**  
   | Symptom | Action |
   |---------|--------|
   | Image pull timeout | Check registry, bump cache TTL |
   | p95 > 75 s | Profile cold-start, open perf ticket |
   | Compose up fails | Sync docker-compose overrides |

5. **Patch & PR**  
   Fix code or workflow, add regression test, open PR referencing failure hash.

6. **Verify**  
   Re-run failed workflow via _Re-run jobs_; confirm green.

## Validation
Green nightly bench for two consecutive runs; p95 metric ≤ 75 s displayed in Grafana.

## Rollback
Revert faulty commit; re-trigger bench workflow.