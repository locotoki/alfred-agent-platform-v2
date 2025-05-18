#!/usr/bin/env python3
"""Benchmark script to demonstrate FAISS performance improvements."""

import time
from typing import List

import numpy as np

from backend.alfred.ml.faiss_index import FAISSIndex
from backend.alfred.search.faiss_tuner import FAISSTuner


def benchmark_index(
    index: FAISSIndex, vectors: np.ndarray, queries: np.ndarray, k: int = 10
) -> dict:
    """Benchmark index performance.

    Args:
        index: FAISS index to benchmark
        vectors: Training vectors
        queries: Query vectors
        k: Number of neighbors

    Returns:
        Performance metrics
    """
    # Add vectors
    ids = [f"id_{i}" for i in range(len(vectors))]
    start = time.time()
    index.add_embeddings(vectors, ids)
    build_time = time.time() - start

    # Run queries
    query_times = []
    for query in queries:
        start = time.time()
        _ = index.search(query, k=k)  # Suppress unused result warning
        query_times.append((time.time() - start) * 1000)  # ms

    p50_ms = np.percentile(query_times, 50)
    p99_ms = np.percentile(query_times, 99)

    return {
        "build_time_s": build_time,
        "p50_query_ms": p50_ms,
        "p99_query_ms": p99_ms,
        "mean_query_ms": np.mean(query_times),
    }


def main():
    """Run performance benchmark comparing different index types."""
    dimension = 384  # MiniLM embedding dimension
    n_vectors = 100000
    n_queries = 1000

    print(f"Generating test data: {n_vectors} vectors, {n_queries} queries")
    np.random.seed(42)
    vectors = np.random.randn(n_vectors, dimension).astype("float32")
    queries = np.random.randn(n_queries, dimension).astype("float32")

    # Benchmark different index types
    index_configs = [
        ("Flat", {}),
        ("IVF", {"nlist": 100}),
        ("HNSW", {}),  # Uses optimized defaults
        ("OPQ+HNSW", {}),  # Uses optimized defaults
    ]

    results = {}

    for index_type, extra_config in index_configs:
        print(f"\nBenchmarking {index_type}...")

        # Create index
        if index_type in ["HNSW", "OPQ+HNSW"]:
            # Use optimized configurations
            index = FAISSIndex(dimension=dimension, index_type=index_type)
        else:
            index = FAISSIndex(dimension=dimension, index_type=index_type, **extra_config)

        # Benchmark
        try:
            metrics = benchmark_index(index, vectors[:10000], queries[:100])
            results[index_type] = metrics

            print(f"{index_type} Results:")
            print(f"  Build time: {metrics['build_time_s']:.2f}s")
            print(f"  Query P50: {metrics['p50_query_ms']:.2f}ms")
            print(f"  Query P99: {metrics['p99_query_ms']:.2f}ms")

        except Exception as e:
            print(f"  Failed: {e}")

    # Compare results
    print("\n" + "=" * 50)
    print("Performance Comparison:")
    print("=" * 50)
    print(f"{'Index Type':<12} {'Build (s)':<10} {'P50 (ms)':<10} {'P99 (ms)':<10}")
    print("-" * 50)

    for index_type, metrics in results.items():
        print(
            f"{index_type:<12} "
            f"{metrics['build_time_s']:<10.2f} "
            f"{metrics['p50_query_ms']:<10.2f} "
            f"{metrics['p99_query_ms']:<10.2f}"
        )

    # Show improvement
    if "Flat" in results and "HNSW" in results:
        flat_p99 = results["Flat"]["p99_query_ms"]
        hnsw_p99 = results["HNSW"]["p99_query_ms"]
        improvement = (flat_p99 - hnsw_p99) / flat_p99 * 100
        print(f"\nHNSW is {improvement:.1f}% faster than Flat index (P99)")

        if hnsw_p99 < 10.0:
            print(f"✓ HNSW achieves sub-10ms P99 latency: {hnsw_p99:.2f}ms")
        else:
            print(f"✗ HNSW P99 latency: {hnsw_p99:.2f}ms (target: <10ms)")

    # Optionally run tuner for more configurations
    print("\n" + "=" * 50)
    print("Running FAISS Tuner (this may take a while)...")
    print("=" * 50)

    tuner = FAISSTuner(
        dimension=dimension,
        target_p99_ms=10.0,
        min_recall=0.95,
    )

    # Run quick tuning on smaller dataset
    tuning_results = tuner.tune(n_vectors=10000, n_queries=100)

    # Find best result
    all_results = tuning_results["HNSW"] + tuning_results["OPQ+HNSW"]
    valid_results = [r for r in all_results if r.query_p99_ms <= 10.0 and r.recall_at_10 >= 0.95]

    if valid_results:
        best = min(valid_results, key=lambda r: r.query_p99_ms)
        print("\nBest configuration found:")
        print(f"  Type: {best.index_type}")
        print(f"  Parameters: {best.parameters}")
        print(f"  P99 latency: {best.query_p99_ms:.2f}ms")
        print(f"  Recall@10: {best.recall_at_10:.3f}")

        # Create index from best result
        print("\nCreating index from best tuning result...")
        best_index = FAISSIndex.from_tuning_result(
            dimension=dimension,
            tuning_result={
                "index_type": best.index_type,
                "parameters": best.parameters,
            },
        )
        print(f"Created {best_index.index_type} index with optimized config")


if __name__ == "__main__":
    main()
