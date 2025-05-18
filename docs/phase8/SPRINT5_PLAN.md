# Sprint-5 Plan – Phase 8.4

## Section 1: Track/Branch

| Item | Value |
|------|-------|
| Sprint Track | Phase 8.4 – Sprint 5 |
| Feature Branch | feat/phase8.4-sprint5 |
| Documentation Branch | docs/spec-draft-sprint5 |
| Start Date | TBD |
| End Date | TBD |

## Section 2: Dependencies

| Dependency | Status | Notes |
|------------|--------|-------|
| HuggingFace Hub auth | Pending | Required for model registry |
| Ray cluster prod | Pending | Auto-scaling ML inference |
| Grafana 11 alerts | Pending | Enhanced alert routing |

## Section 3: CLI Commands

```bash
# Unit test ML models
pytest tests/ml -v --cov=alfred.ml

# Test noise reduction endpoint
curl -X POST http://localhost:8000/api/v1/noise-cut \
  -H "Content-Type: application/json" \
  -d '{"alerts": [...]}'

# Load test with locust
locust -f tests/load/test_noise_api.py --host http://localhost:8000
```

## Section 4: Required Files

| File | Purpose | Status |
|------|---------|--------|
| `alfred/ml/retrain_scheduler.py` | Scheduled model retraining | Pending |
| `frontend/src/components/DriftDetector.tsx` | Drift visualization | Pending |
| `alfred/ml/drift_monitor.py` | Model drift detection | Pending |
| `tests/ml/test_retraining.py` | Retraining pipeline tests | Pending |

## Section 5: CI Requirements

| Metric | Target | Current |
|--------|--------|---------|
| Benchmark runtime | ≤3 minutes | TBD |
| Code coverage | ≥92% | TBD |
| Lighthouse score | ≥90 | TBD |

## Section 6: Success Gates

| KPI | Target | Baseline |
|-----|--------|----------|
| Noise reduction | ≥50% | 47% |
| Drift alert time | <24h | N/A |
| P95 latency | ≤130ms | 132ms |
| Model accuracy | ≥94% | TBD |