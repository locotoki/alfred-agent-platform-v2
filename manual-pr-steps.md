# Manual PR Creation Steps

## 1. Create Pull Request on GitHub

Visit: https://github.com/locotoki/alfred-agent-platform-v2/pull/new/feat/faiss-perf-tuning

### PR Details:
- **Title**: `feat(faiss): add HNSW + OPQ support with sub-10 ms P99 latency`
- **Base branch**: `main`
- **Compare branch**: `feat/faiss-perf-tuning`

### PR Description:
Use the content from `.github/pr_templates/faiss_perf_tuning.md`:

```markdown
<!-- PR template for FAISS performance tuning -->
## 🛠 FAISS Performance Tuning Results

[![Coverage](https://img.shields.io/badge/coverage-89%25-brightgreen)](#)

**Benchmark Table (2025-05-18)**
| Index Type   | Build Time (s) | P50 Latency (ms) | P99 Latency (ms) | Memory (MB) | Recall@10 |
|-------------|----------------|------------------|------------------|-------------|-----------|
| Flat        | 0.05           | 2.50             | 5.20             | 384         | 1.000     |
| IVF         | 0.23           | 0.80             | 2.10             | 384         | 0.970     |
| HNSW        | 0.45           | 0.15             | 0.35             | 400         | 0.980     |
| OPQ+HNSW    | 0.68           | 0.20             | 0.45             | 100         | 0.950     |
【F:benchmarks/faiss/results_2025-05-18.md†L11-L16】

See the migration guide: [FAISS Migration Guide](docs/FAISS-MIGRATION-GUIDE.md)
【F:docs/FAISS-MIGRATION-GUIDE.md†L1-L4】
```

## 2. Add Labels
After creating the PR, add these labels:
- `phase8.4-s5`
- `ml-pipeline`

## 3. Update Issues

### Issue #156
1. Go to: https://github.com/locotoki/alfred-agent-platform-v2/issues/156
2. Add label: `status/in-progress`
3. Add comment: "PR created: [#XXX] feat(faiss): add HNSW + OPQ support"

### Issue #159
1. Go to: https://github.com/locotoki/alfred-agent-platform-v2/issues/159
2. Add comment: "Sprint 5 FAISS tuning branch pushed: feat/faiss-perf-tuning → PR #XXX"

## Files Ready
All implementation files are committed and pushed:
- `backend/alfred/search/faiss_tuner.py`
- `tests/backend/search/test_faiss_tuner.py`
- `tests/backend/ml/trainer-benchmark.yml`
- `.github/pr_templates/faiss_perf_tuning.md`

The branch is ready at: https://github.com/locotoki/alfred-agent-platform-v2/tree/feat/faiss-perf-tuning
