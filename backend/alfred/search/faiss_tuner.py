"""FAISS index performance tuner with HNSW and OPQ trials."""

import json
import time
from dataclasses import dataclass
from typing import Dict, List, Optional, Tuple

import faiss
import numpy as np
import structlog

logger = structlog.get_logger()


@dataclass
class TuningResult:
    """Results from a FAISS index tuning trial."""

    index_type: str
    parameters: Dict[str, float]
    query_p99_ms: float
    recall_at_10: float
    build_time_s: float
    memory_mb: float

    def __str__(self) -> str:
        """Return string representation of tuning result."""
        return (
            f"{self.index_type} - P99: {self.query_p99_ms:.2f}ms, "
            f"Recall@10: {self.recall_at_10:.3f}, Memory: {self.memory_mb:.1f}MB"
        )


class FAISSTuner:
    """Tunes FAISS index parameters for optimal performance."""

    def __init__(
        self,
        dimension: int,
        target_p99_ms: float = 10.0,
        min_recall: float = 0.95,
    ):
        """Initialize FAISS tuner.

        Args:
            dimension: Vector dimension
            target_p99_ms: Target 99th percentile query latency in milliseconds
            min_recall: Minimum acceptable recall@10
        """
        self.dimension = dimension
        self.target_p99_ms = target_p99_ms
        self.min_recall = min_recall
        self.logger = logger.bind(
            component="faiss_tuner",
            dimension=dimension,
            target_p99_ms=target_p99_ms,
        )

    def generate_test_data(
        self, n_vectors: int = 100000, n_queries: int = 1000
    ) -> Tuple[np.ndarray, np.ndarray, np.ndarray]:
        """Generate synthetic test data.

        Args:
            n_vectors: Number of vectors in the index
            n_queries: Number of query vectors

        Returns:
            Tuple of (vectors, queries, ground_truth_ids)
        """
        np.random.seed(42)
        vectors = np.random.randn(n_vectors, self.dimension).astype("float32")
        queries = np.random.randn(n_queries, self.dimension).astype("float32")

        # Compute ground truth using brute force
        index_flat = faiss.IndexFlatL2(self.dimension)
        index_flat.add(vectors)
        _, ground_truth = index_flat.search(queries, 10)

        return vectors, queries, ground_truth

    def _build_hnsw_index(
        self, vectors: np.ndarray, m: int = 16, ef_construction: int = 200
    ) -> faiss.Index:
        """Build HNSW index with specified parameters.

        Args:
            vectors: Training vectors
            m: Number of bi-directional links per layer
            ef_construction: Size of the dynamic candidate list

        Returns:
            Trained HNSW index
        """
        index = faiss.IndexHNSWFlat(self.dimension, m)
        index.hnsw.efConstruction = ef_construction
        index.add(vectors)
        return index

    def _build_opq_hnsw_index(
        self,
        vectors: np.ndarray,
        m_pq: int = 8,
        n_subquantizers: int = 32,
        m_hnsw: int = 16,
        ef_construction: int = 200,
    ) -> faiss.Index:
        """Build OPQ+HNSW composite index.

        Args:
            vectors: Training vectors
            m_pq: Number of bytes per vector for PQ
            n_subquantizers: Number of sub-quantizers for PQ
            m_hnsw: Number of bi-directional links per layer for HNSW
            ef_construction: Size of the dynamic candidate list

        Returns:
            Trained OPQ+HNSW index
        """
        # Create OPQ pre-processor
        opq = faiss.OPQMatrix(self.dimension, m_pq, n_subquantizers)

        # Create PQ index
        pq_index = faiss.IndexPQ(self.dimension, m_pq, n_subquantizers)

        # Wrap with HNSW
        index_hnsw = faiss.IndexHNSWFlat(self.dimension, m_hnsw)
        index_hnsw.hnsw.efConstruction = ef_construction

        # Combine: OPQ -> PQ -> HNSW
        index = faiss.IndexPreTransform(opq, pq_index)

        # Train and add vectors
        opq.train(vectors)
        index.add(vectors)

        return index

    def _evaluate_index(
        self,
        index: faiss.Index,
        queries: np.ndarray,
        ground_truth: np.ndarray,
        n_runs: int = 100,
    ) -> Tuple[float, float, float]:
        """Evaluate index performance.

        Args:
            index: FAISS index to evaluate
            queries: Query vectors
            ground_truth: Ground truth nearest neighbors
            n_runs: Number of query runs for timing

        Returns:
            Tuple of (query_p99_ms, recall_at_10, memory_mb)
        """
        # Measure query latency
        query_times = []
        for _ in range(n_runs):
            start = time.perf_counter()
            index.search(queries[:10], 10)  # Small batch for consistent timing
            query_times.append((time.perf_counter() - start) * 1000 / 10)

        query_p99_ms = np.percentile(query_times, 99)

        # Measure recall
        _, retrieved_ids = index.search(queries, 10)
        recalls = []
        for i in range(len(queries)):
            intersection = len(set(retrieved_ids[i]) & set(ground_truth[i]))
            recalls.append(intersection / 10.0)
        recall_at_10 = np.mean(recalls)

        # Estimate memory usage
        memory_mb = index.ntotal * self.dimension * 4 / (1024 * 1024)
        if hasattr(index, "pq"):
            # PQ uses less memory
            memory_mb *= 0.25

        return query_p99_ms, recall_at_10, memory_mb

    def tune_hnsw(
        self,
        vectors: np.ndarray,
        queries: np.ndarray,
        ground_truth: np.ndarray,
    ) -> List[TuningResult]:
        """Tune HNSW parameters.

        Args:
            vectors: Training vectors
            queries: Query vectors
            ground_truth: Ground truth nearest neighbors

        Returns:
            List of tuning results
        """
        results = []

        # Grid search over HNSW parameters
        for m in [8, 16, 32, 64]:
            for ef_construction in [100, 200, 400]:
                self.logger.info(
                    "Testing HNSW configuration",
                    m=m,
                    ef_construction=ef_construction,
                )

                # Build index
                start_build = time.perf_counter()
                index = self._build_hnsw_index(vectors, m, ef_construction)
                build_time = time.perf_counter() - start_build

                # Set search parameters
                for ef_search in [16, 32, 64, 128, 256]:
                    index.hnsw.efSearch = ef_search

                    # Evaluate
                    query_p99_ms, recall_at_10, memory_mb = self._evaluate_index(
                        index, queries, ground_truth
                    )

                    result = TuningResult(
                        index_type="HNSW",
                        parameters={
                            "m": m,
                            "ef_construction": ef_construction,
                            "ef_search": ef_search,
                        },
                        query_p99_ms=query_p99_ms,
                        recall_at_10=recall_at_10,
                        build_time_s=build_time,
                        memory_mb=memory_mb,
                    )

                    results.append(result)
                    self.logger.info("HNSW trial complete", result=str(result))

                    # Early termination if target met
                    if query_p99_ms <= self.target_p99_ms and recall_at_10 >= self.min_recall:
                        return results

        return results

    def tune_opq_hnsw(
        self,
        vectors: np.ndarray,
        queries: np.ndarray,
        ground_truth: np.ndarray,
    ) -> List[TuningResult]:
        """Tune OPQ+HNSW parameters.

        Args:
            vectors: Training vectors
            queries: Query vectors
            ground_truth: Ground truth nearest neighbors

        Returns:
            List of tuning results
        """
        results = []

        # Grid search over OPQ+HNSW parameters
        for m_pq in [8, 16, 32]:
            for n_subquantizers in [16, 32, 64]:
                for m_hnsw in [8, 16, 32]:
                    self.logger.info(
                        "Testing OPQ+HNSW configuration",
                        m_pq=m_pq,
                        n_subquantizers=n_subquantizers,
                        m_hnsw=m_hnsw,
                    )

                    # Build index
                    start_build = time.perf_counter()
                    try:
                        index = self._build_opq_hnsw_index(vectors, m_pq, n_subquantizers, m_hnsw)
                        build_time = time.perf_counter() - start_build
                    except Exception as e:
                        self.logger.warning(
                            "Failed to build OPQ+HNSW index",
                            error=str(e),
                            m_pq=m_pq,
                            n_subquantizers=n_subquantizers,
                        )
                        continue

                    # Evaluate
                    query_p99_ms, recall_at_10, memory_mb = self._evaluate_index(
                        index, queries, ground_truth
                    )

                    result = TuningResult(
                        index_type="OPQ+HNSW",
                        parameters={
                            "m_pq": m_pq,
                            "n_subquantizers": n_subquantizers,
                            "m_hnsw": m_hnsw,
                        },
                        query_p99_ms=query_p99_ms,
                        recall_at_10=recall_at_10,
                        build_time_s=build_time,
                        memory_mb=memory_mb,
                    )

                    results.append(result)
                    self.logger.info("OPQ+HNSW trial complete", result=str(result))

                    # Early termination if target met
                    if query_p99_ms <= self.target_p99_ms and recall_at_10 >= self.min_recall:
                        return results

        return results

    def tune(
        self,
        n_vectors: int = 100000,
        n_queries: int = 1000,
    ) -> Dict[str, List[TuningResult]]:
        """Run full tuning process.

        Args:
            n_vectors: Number of vectors for testing
            n_queries: Number of queries for testing

        Returns:
            Dictionary mapping index type to list of results
        """
        self.logger.info(
            "Starting FAISS tuning",
            n_vectors=n_vectors,
            n_queries=n_queries,
        )

        # Generate test data
        vectors, queries, ground_truth = self.generate_test_data(n_vectors, n_queries)

        results = {
            "HNSW": self.tune_hnsw(vectors, queries, ground_truth),
            "OPQ+HNSW": self.tune_opq_hnsw(vectors, queries, ground_truth),
        }

        # Find best configuration
        all_results = results["HNSW"] + results["OPQ+HNSW"]
        valid_results = [
            r
            for r in all_results
            if r.query_p99_ms <= self.target_p99_ms and r.recall_at_10 >= self.min_recall
        ]

        if valid_results:
            best_result = min(valid_results, key=lambda r: r.query_p99_ms)
            self.logger.info(
                "Tuning complete - found valid configuration",
                best_result=str(best_result),
            )
        else:
            self.logger.warning(
                "Tuning complete - no configuration met targets",
                target_p99_ms=self.target_p99_ms,
                min_recall=self.min_recall,
            )

        return results

    def save_results(self, results: Dict[str, List[TuningResult]], filepath: str) -> None:
        """Save tuning results to JSON file.

        Args:
            results: Tuning results to save
            filepath: Path to save results
        """
        serializable_results = {}
        for index_type, result_list in results.items():
            serializable_results[index_type] = [
                {
                    "index_type": r.index_type,
                    "parameters": r.parameters,
                    "query_p99_ms": r.query_p99_ms,
                    "recall_at_10": r.recall_at_10,
                    "build_time_s": r.build_time_s,
                    "memory_mb": r.memory_mb,
                }
                for r in result_list
            ]

        with open(filepath, "w") as f:
            json.dump(serializable_results, f, indent=2)

        self.logger.info("Saved tuning results", filepath=filepath)
