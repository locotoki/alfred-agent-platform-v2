# Phase 8.3 Sprint 2 - Alert Grouping Enhancement

## 🎯 Sprint Goals
1. Implement advanced grouping heuristics
2. Add merge/unmerge UI controls
3. Deploy comprehensive metrics
4. Execute canary rollout
5. Complete production rollout

## 📋 Issue Mapping

| Branch | Issue | Description |
|--------|-------|-------------|
| feat/grouping-heuristics | #110 | Enhanced similarity algorithms |
| feat/group-merge-ui | #111 | Manual merge/unmerge controls |
| feat/group-metrics | #112 | Grafana dashboards & metrics |
| chore/rollout-plan | #113 | Production rollout documentation |
| chore/canary-deploy | #114 | 5% canary deployment |
| test/e2e-user-feedback | #115 | E2E tests with user flows |

## 🔧 Technical Requirements

### Dependencies
- python-Levenshtein ≥0.25
- Grafana 10.x with Loki
- React Query ^5.0
- Feature flag service (Unleash/ENV)
- SLACK_PROD_WEBHOOK

### Performance Targets
- P95 latency < 150ms
- Coverage ≥ 88%
- Lighthouse score ≥ 90

### Key Files
- `backend/alfred/alerts/grouping_v2.py`
- `frontend/src/components/GroupedAlertsControls.tsx`
- `metrics/dashboards/alert_grouping.json`
- `docs/ops/alert-grouping-rollout.md`

## ✅ Acceptance Criteria
1. Canary shows P95 < 150ms for 72h
2. Merge/unmerge reflected within 2s
3. Grafana dashboards published
4. 100% rollout completed
5. Sprint board closed

## 🚀 Deployment Plan
1. Deploy to canary (5%)
2. Monitor for 72h
3. Expand to 25%
4. Monitor for 24h
5. Full production rollout
6. Post Slack notification