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
