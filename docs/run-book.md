# Platform Run-Book 🚑 *(GA v3.0.0)*

> **Status:** _Draft — Post-β Hardening_
> **Last updated:** $(date +"%Y-%m-%d")

## 1  Start-up Procedure
1. `alfred up` — cold-start **≤ 60 s** _(bench SLA ≤ 75 s)_
2. Verify containers: `docker compose ps --status running`
   <\!-- TODO: elaborate fast-fail checks & health probes -->

## 2  Graceful Shutdown
1. `alfred down`
2. Check lingering volumes and networks
   <\!-- TODO: document known caveats on macOS / WSL2 -->

## 3  Common Issues & Fixes
 < /dev/null |  Symptom | Probable Cause | Quick Fix |
| --- | --- | --- |
| Cold-start > 75 s | Missing cache images | Run `alfred build --pull` |

<\!-- TODO: flesh out more scenarios -->

## 4  Cold-Start SLA Verification
```bash
alfred bench cold-start --run 5 --json > bench.json
# TODO: add jq one-liner to assert p95 ≤ 75s
```
