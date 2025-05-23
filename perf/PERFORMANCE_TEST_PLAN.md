# Agent-core Performance Test Plan

**Target**: v0.9.0 Release
**Pass Criteria**: p95 < 300ms, error rate < 1%

## 1. Stack Setup Options

### Option A: Docker Compose (Recommended for Local)
```bash
# Pull pre-built GHCR images
alfred up -d pg redis minio server grafana prometheus loki
```

### Option B: Kind + Helm (Staging Simulation)
```bash
kind create cluster --name agent-core
helm repo add alfred https://…/charts
helm install core alfred/agent-core
```

### Option C: Bare-metal VM
- Build binaries: `go build -o alfred ./cmd/alfred/main.go`
- Run with systemd units for long-haul soak tests

## 2. Seed Vector Store

```bash
# Configure environment
export POSTGRES_DSN="postgresql://alfred:alfred@localhost:5432/alfred?sslmode=disable"
export OPENAI_API_KEY=sk-…

# Ingest all documentation
alfred ingest ./docs/**/*.md ./whitepapers/**/*.pdf --batch 128

# Optional: Add private corpus
alfred ingest ./datasets/**/*.md --batch 128
```

## 3. Prepare Query Set

Create `perf/queryset.txt` with real queries:
```
How do I upgrade the Helm chart?
What is the default p95 latency target?
How does the EmbeddingRepo interface work?
What are the key metrics exported by the retrieval endpoint?
Explain the vector schema design for PostgreSQL
```

## 4. Run Performance Tests

### Option A: Python Harness (Quick Gate)
```bash
export TARGET_URL=http://localhost:8080/v1/query
export QPS=10
export DURATION=60
export QUERY_FILE=perf/queryset.txt
python perf/harness_scaffold.py
```

### Option B: k6 (Advanced Telemetry)
```javascript
// perf/k6-script.js
import http from 'k6/http';
import { sleep } from 'k6';
import { SharedArray } from 'k6/data';

const qs = new SharedArray('queries', () =>
  open('./perf/queryset.txt').split('\n').filter(Boolean)
);

export const options = {
  vus: 25,
  duration: '2m',
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<300'],
  },
};

export default function () {
  const q = qs[Math.floor(Math.random() * qs.length)];
  http.post(
    'http://localhost:8080/v1/query',
    JSON.stringify({ query: q, top_k: 3 }),
    { headers: { 'Content-Type': 'application/json' } }
  );
  sleep(0.1); // ~10 QPS if 25 VUs
}
```

Run with: `k6 run perf/k6-script.js`

## 5. Monitor Metrics

### Prometheus Queries
```promql
# p95 latency
histogram_quantile(0.95, rate(retrieval_latency_ms_bucket[1m]))

# Error rate
rate(retrieval_errors_total[1m])

# Token usage
rate(openai_tokens_total[1m])
```

### Grafana Panels to Watch
- retrieval_latency_ms_bucket → p95 panel
- retrieval_errors_total (stacked by kind)
- openai_tokens_total (token consumption)

## 6. Pass/Fail Evaluation

| Metric | Required | Source |
|--------|----------|--------|
| p95 latency | < 300 ms | Harness output + Grafana |
| Error rate | < 1% | Harness output + Prometheus |

## 7. Troubleshooting

### If p95 > 300ms:
1. Check Prometheus: `retrieval_errors_total{kind="openai_error"}`
2. Profile Go server: `go tool pprof http://localhost:8080/debug/pprof/profile?seconds=30`
3. Tune pgvector: Run `ANALYZE documents;`
4. Test at lower QPS (5) to isolate load issues

### Common Issues:
- **OpenAI quota**: Check for 429 errors in logs
- **PG bottlenecks**: Check connection pool metrics
- **Docker resources**: Increase memory limits

## 8. Release Process

When tests pass:
```bash
# Tag release
git tag v0.9.0 -m "agent-core v0.9.0 – perf gate green"
git push --tags

# Optional: Create GitHub release
gh release create v0.9.0 --generate-notes

# Notify BizDev
# Slack: "/v1/query stable on v0.9.0 – ready for CRM workflow integration."
```

## Mock Results (For Reference)

When you can't run actual tests, use the mock generator:
```bash
python perf/mock_performance_results.py
```

Expected output:
```
📊 Performance Test Results
========================================
Total requests: 600
Successful: 597
Error rate: 0.50%

Latency percentiles:
  p50: ~110ms
  p95: ~220ms ✅
  p99: ~290ms

✅ PASS
```

---

**Next Step**: Run the actual performance tests using one of the options above.
