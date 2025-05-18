# FAISS Index Configuration Migration Guide

This guide covers the configuration changes required for existing deployments to use the new FAISS performance optimizations.

## Overview of Changes

1. **Default Index Type**: Changed from `IVF` to `HNSW`
2. **New Index Type**: Added `OPQ+HNSW` for memory-efficient deployments
3. **Configuration Structure**: Added support for custom index parameters

## Migration Steps

### 1. Environment Variables

**Before (v0.8.x):**
```bash
FAISS_INDEX_TYPE=IVF
FAISS_NLIST=100
FAISS_NPROBE=10
```

**After (v0.9.0+):**
```bash
# Option 1: Use optimized defaults (recommended)
FAISS_INDEX_TYPE=HNSW  # or OPQ+HNSW for memory-constrained environments

# Option 2: Custom configuration
FAISS_INDEX_TYPE=HNSW
FAISS_CONFIG_M=32
FAISS_CONFIG_EF_CONSTRUCTION=200
FAISS_CONFIG_EF_SEARCH=64
```

### 2. Code Changes

**Before:**
```python
from backend.alfred.ml.faiss_index import FAISSIndex

# Old way
index = FAISSIndex(
    dimension=384,
    index_type="IVF",
    nlist=100,
    nprobe=10
)
```

**After:**
```python
from backend.alfred.ml.faiss_index import FAISSIndex

# Option 1: Use optimized defaults (recommended)
index = FAISSIndex(
    dimension=384,
    index_type="HNSW"  # Will use optimized config automatically
)

# Option 2: Custom configuration
index = FAISSIndex(
    dimension=384,
    index_type="HNSW",
    config={
        "m": 16,
        "ef_construction": 100,
        "ef_search": 32
    }
)

# Option 3: From tuning results
from backend.alfred.search.faiss_tuner import FAISSTuner

tuner = FAISSTuner(dimension=384)
results = tuner.tune()
# ... select best result ...
index = FAISSIndex.from_tuning_result(
    dimension=384,
    tuning_result=best_result
)
```

### 3. Configuration Files

**Before (`config/ml/faiss.yaml`):**
```yaml
faiss:
  index_type: IVF
  nlist: 100
  nprobe: 10
  device: cpu
```

**After (`config/ml/faiss.yaml`):**
```yaml
faiss:
  index_type: HNSW  # or OPQ+HNSW
  device: cpu
  
  # Optional: Custom configuration
  config:
    m: 32
    ef_construction: 200
    ef_search: 64
    
  # OPQ+HNSW specific (if using)
  # config:
  #   m_pq: 8
  #   n_subquantizers: 32
  #   m_hnsw: 16
  #   ef_construction: 200
  #   ef_search: 64
```

### 4. Helm Chart Values

**Before (`values.yaml`):**
```yaml
ml:
  faiss:
    indexType: IVF
    nlist: 100
    nprobe: 10
```

**After (`values.yaml`):**
```yaml
ml:
  faiss:
    indexType: HNSW  # or OPQ+HNSW
    
    # Optional: Override default config
    config:
      m: 32
      efConstruction: 200
      efSearch: 64
```

## Existing Index Migration

If you have an existing IVF index in production:

### Option 1: Reindex (Recommended)

```python
# 1. Load existing data
old_index = FAISSIndex(dimension=384, index_type="IVF")
old_index.load_index("path/to/old/index")

# 2. Extract embeddings and metadata
# Note: You'll need to have stored embeddings separately
embeddings = load_embeddings_from_storage()
alert_ids = list(old_index.id_map.values())
metadata = old_index.metadata

# 3. Create new optimized index
new_index = FAISSIndex(dimension=384, index_type="HNSW")

# 4. Reindex data
new_index.add_embeddings(embeddings, alert_ids, metadata)

# 5. Save new index
new_index.save_index("path/to/new/index")
```

### Option 2: Gradual Migration

```python
# Use feature flag to switch between indexes
if FEATURE_FLAG_NEW_FAISS:
    index = FAISSIndex(dimension=384, index_type="HNSW")
else:
    index = FAISSIndex(dimension=384, index_type="IVF", nlist=100)
```

## Performance Comparison

| Metric | IVF (Old) | HNSW (New Default) | OPQ+HNSW |
|--------|-----------|-------------------|----------|
| P99 Latency | 2.1ms | 0.35ms | 0.45ms |
| Memory (1M alerts) | 1.5GB | 1.5GB | 384MB |
| Build Time | Fast | Moderate | Slower |
| Recall@10 | 0.97 | 0.98 | 0.95 |

## Rollback Plan

If you need to rollback:

1. Set `FAISS_INDEX_TYPE=IVF` in environment
2. Restore old index files
3. Restart services

The code maintains backward compatibility with IVF indexes.

## Monitoring

After migration, monitor these metrics:

1. Query latency (P50, P90, P99)
2. Memory usage
3. Search recall/precision
4. Index build times

```python
# Get performance stats
stats = index.get_stats()
print(f"P99 latency: {stats['p99_query_time_ms']}ms")
print(f"Total vectors: {stats['total_vectors']}")
```

## FAQ

**Q: Will my existing IVF index still work?**  
A: Yes, the code maintains full backward compatibility.

**Q: When should I use OPQ+HNSW instead of HNSW?**  
A: Use OPQ+HNSW when you have >1M alerts or memory constraints.

**Q: How do I tune the configuration?**  
A: Use the `FAISSTuner` class or start with defaults and adjust based on monitoring.

**Q: What's the minimum Python/FAISS version?**  
A: Python 3.8+ and faiss-cpu 1.7.4+ (or faiss-gpu for GPU support).

## Support

For questions or issues:
- Check the [performance tuning guide](./faiss-performance-tuning.md)
- Open an issue with the `faiss` label
- Review benchmark results in `benchmarks/faiss/`