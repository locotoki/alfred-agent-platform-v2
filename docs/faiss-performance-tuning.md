# FAISS Performance Tuning Guide

This guide explains the FAISS performance optimizations implemented in the Alfred platform.

## Overview

The Alfred platform uses Facebook's FAISS library for fast similarity search of alert embeddings. To achieve sub-15ms P99 query latency, we've implemented several optimizations:

1. **HNSW (Hierarchical Navigable Small World)** - Default index type for best performance
2. **OPQ+HNSW** - Optimized Product Quantization with HNSW for memory-efficient search
3. **Automatic Tuning** - Built-in performance tuner to find optimal configurations

## Index Types

### HNSW (Default)

HNSW provides excellent query performance with moderate memory usage:

```python
from backend.alfred.ml.faiss_index import FAISSIndex

# Creates HNSW index with optimized defaults
index = FAISSIndex(
    dimension=384,
    index_type="HNSW"  # Default configuration
)
```

Default HNSW configuration:
- `m`: 32 (number of bi-directional links)
- `ef_construction`: 200 (construction-time search effort)
- `ef_search`: 64 (query-time search effort)

### OPQ+HNSW

For memory-constrained environments, OPQ+HNSW reduces memory usage while maintaining good performance:

```python
index = FAISSIndex(
    dimension=384,
    index_type="OPQ+HNSW"
)
```

Default OPQ+HNSW configuration:
- `m_pq`: 8 (bytes per vector)
- `n_subquantizers`: 32
- `m_hnsw`: 16
- `ef_construction`: 200
- `ef_search`: 64

### Custom Configuration

You can override the default configurations:

```python
custom_config = {
    "m": 16,
    "ef_construction": 100,
    "ef_search": 32,
}

index = FAISSIndex(
    dimension=384,
    index_type="HNSW",
    config=custom_config
)
```

## Performance Tuning

Use the FAISSTuner to find optimal configurations for your specific use case:

```python
from backend.alfred.search.faiss_tuner import FAISSTuner

tuner = FAISSTuner(
    dimension=384,
    target_p99_ms=10.0,  # Target P99 latency
    min_recall=0.95      # Minimum acceptable recall
)

# Run tuning (this may take a while)
results = tuner.tune(n_vectors=100000, n_queries=1000)

# Find best configuration
all_results = results["HNSW"] + results["OPQ+HNSW"]
valid_results = [
    r for r in all_results
    if r.query_p99_ms <= tuner.target_p99_ms
    and r.recall_at_10 >= tuner.min_recall
]

if valid_results:
    best = min(valid_results, key=lambda r: r.query_p99_ms)

    # Create index from best result
    index = FAISSIndex.from_tuning_result(
        dimension=384,
        tuning_result={
            "index_type": best.index_type,
            "parameters": best.parameters,
        }
    )
```

## Benchmarking

To benchmark different index types:

```bash
cd backend/alfred/ml
python faiss_benchmark.py
```

This will compare performance across different index types:

```
Index Type    Build (s)   P50 (ms)   P99 (ms)
--------------------------------------------------
Flat          0.05        2.50       5.20
IVF           0.23        0.80       2.10
HNSW          0.45        0.15       0.35
OPQ+HNSW      0.68        0.20       0.45

HNSW is 93.3% faster than Flat index (P99)
✓ HNSW achieves sub-10ms P99 latency: 0.35ms
```

## Usage in AlertSearchEngine

The AlertSearchEngine now defaults to HNSW for optimal performance:

```python
from backend.alfred.ml.faiss_index import AlertSearchEngine

# Creates engine with HNSW index by default
engine = AlertSearchEngine()

# Index alerts
alerts = [
    {
        "id": "1",
        "name": "Database Error",
        "description": "Connection timeout",
        "severity": "critical"
    },
    # ... more alerts
]

engine.index_alerts(alerts)

# Search for similar alerts
results = engine.search_similar(
    "database connection failure",
    k=10,
    threshold=0.7
)

# Get performance stats
stats = engine.get_performance_stats()
print(f"Query P99: {stats['p99_query_time_ms']:.2f}ms")
```

## Memory Considerations

- **HNSW**: ~4 bytes per dimension per vector
- **OPQ+HNSW**: ~1 byte per dimension per vector (75% reduction)

For 1M alerts with 384-dimensional embeddings:
- HNSW: ~1.5 GB
- OPQ+HNSW: ~384 MB

## Best Practices

1. **Use HNSW by default** - Best balance of speed and accuracy
2. **Use OPQ+HNSW for large datasets** - When memory is a constraint
3. **Run tuning for production** - Find optimal parameters for your data
4. **Monitor performance** - Use `get_stats()` to track query latencies
5. **Batch operations** - Use `batch_search()` for multiple queries

## Migration from Existing Indexes

If you have existing indexes, migrate to the optimized versions:

```python
# Load existing index
old_index = FAISSIndex(dimension=384, index_type="IVF")
old_index.load_index("old_index_path")

# Extract data
# (Note: In practice, you'd need to store embeddings separately)

# Create new optimized index
new_index = FAISSIndex(dimension=384, index_type="HNSW")

# Re-index data
# new_index.add_embeddings(embeddings, ids, metadata)

# Save new index
new_index.save_index("new_index_path")
```

## Troubleshooting

### High Query Latency

1. Check index type - ensure using HNSW
2. Verify search parameters - adjust `ef_search`
3. Consider data size - use OPQ+HNSW for very large datasets
4. Run tuning to find optimal parameters

### Low Recall

1. Increase `ef_search` for HNSW
2. Increase `nprobe` for IVF
3. Consider using Flat index for small datasets (<10K vectors)

### Memory Issues

1. Switch to OPQ+HNSW
2. Reduce number of subquantizers
3. Consider sharding the index

## References

- [FAISS GitHub](https://github.com/facebookresearch/faiss)
- [FAISS Wiki](https://github.com/facebookresearch/faiss/wiki)
- [HNSW Paper](https://arxiv.org/abs/1603.09320)
- [Product Quantization](https://hal.inria.fr/inria-00514462v2/document)
