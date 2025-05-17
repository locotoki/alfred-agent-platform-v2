# Sprint 4 Plan - ML Enhancements & SLO

## 1. Track/Branch Table

| Branch | Target | Description |
|--------|--------|-------------|
| feat/ml-retrain-pipeline | feat/phase8.3-sprint4 | Automated model retraining |
| feat/dynamic-thresholds | feat/phase8.3-sprint4 | Adaptive noise thresholds |
| feat/huggingface-models | feat/phase8.3-sprint4 | HuggingFace integration |
| feat/slo-dashboard | feat/phase8.3-sprint4 | SLO monitoring in Grafana |
| test/retrain-benchmark | feat/phase8.3-sprint4 | Performance benchmarks |
| docs/ml-operations | feat/phase8.3-sprint4 | MLOps documentation |

## 2. Dependencies Table

| Dependency | Version | Purpose | License |
|------------|---------|---------|---------|
| Ray | 2.10.0 | Distributed training | Apache 2.0 |
| HuggingFace Transformers | 4.37.0 | Pre-trained models | Apache 2.0 |
| FAISS | 1.7.4 | HNSW vector search | MIT |
| Grafana | 11.0.0 | SLO dashboards | AGPL 3.0 |
| MLflow | 2.11.0 | Model versioning | Apache 2.0 |
| DVC | 3.42.0 | Data versioning | Apache 2.0 |

## 3. Acceptance-test CLI Examples

### Unit Tests
```bash
# Run ML pipeline tests
pytest tests/ml/test_retrain_pipeline.py -v
pytest tests/ml/test_model_selection.py -v
pytest tests/ml/test_threshold_optimizer.py -v
```

### Integration Tests
```bash
# Test model training endpoint
curl -X POST http://localhost:8000/api/v1/ml/retrain \
  -H "Content-Type: application/json" \
  -d '{"dataset": "alerts-2025q1", "hyperparams": {"n_estimators": 300}}'

# Test threshold adjustment
curl -X PUT http://localhost:8000/api/v1/ml/thresholds \
  -H "Content-Type: application/json" \
  -d '{"service": "api-gateway", "threshold": 0.75}'
```

### Load Tests
```bash
# Benchmark model inference
locust -f tests/load/ml_inference.py \
  --host http://localhost:8000 \
  --users 100 --spawn-rate 10 \
  --run-time 300

# Benchmark retraining pipeline
python scripts/benchmark_training.py \
  --dataset synthetic-alerts-1m \
  --output benchmark_report.json
```

## 4. Required Files

| File | Purpose | Location |
|------|---------|----------|
| trainer.py | Core ML training logic | `alfred/ml/trainer.py` |
| retrain_scheduler.py | Automated retraining | `alfred/ml/scheduler.py` |
| thresholds_ui.tsx | Dynamic threshold UI | `frontend/src/views/ThresholdsUI.tsx` |
| model_selector.py | Model A/B testing | `alfred/ml/selector.py` |
| slo_dash.json | SLO dashboard config | `grafana/dashboards/slo_dash.json` |
| noise_analyzer.sql | Data analysis queries | `sql/analytics/noise_analyzer.sql` |

## 5. CI Expectations

### Performance Requirements
- trainer-benchmark.yml must complete in < 3 minutes
- Model inference P99 latency < 15ms
- Training pipeline memory usage < 16GB
- Code coverage must be ≥ 92%

### CI Workflows
```yaml
trainer-benchmark.yml:
  - Train on 100k synthetic alerts
  - Validate model accuracy > 90%
  - Check false negative rate < 1.5%
  - Time limit: 3 minutes

ml-integration.yml:
  - Test model serving endpoints
  - Verify threshold updates
  - Check Grafana dashboard
  - Coverage report > 92%
```

## 6. Acceptance Gates

### Performance Metrics
| Metric | Target | Priority |
|--------|--------|----------|
| Noise reduction | ≥ 45% | Critical |
| P95 inference latency | ≤ 140ms | Critical |
| False negative rate | < 1.5% | Critical |
| Training time (100k alerts) | < 5min | High |
| Model size | < 500MB | Medium |

### SLO Requirements
- Alert noise reduction SLO: 99.9% uptime
- Model accuracy SLO: 90% precision maintained
- Retraining frequency: Weekly minimum
- Rollback capability: < 5 minutes

### Monitoring
- Grafana dashboard with:
  - Noise reduction trends
  - Model performance metrics
  - Training pipeline status
  - SLO burn rate alerts