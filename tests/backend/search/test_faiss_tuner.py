"""Tests for FAISS performance tuner."""

import json
import tempfile
import unittest
from unittest.mock import Mock, patch

import numpy as np

from backend.alfred.search.faiss_tuner import FAISSTuner, TuningResult


class TestFAISSTuner(unittest.TestCase):
    """Test cases for FAISSTuner."""

    def setUp(self):
        """Set up test fixtures."""
        self.dimension = 128
        self.tuner = FAISSTuner(
            dimension=self.dimension,
            target_p99_ms=10.0,
            min_recall=0.95,
        )

    def test_init(self):
        """Test tuner initialization."""
        self.assertEqual(self.tuner.dimension, self.dimension)
        self.assertEqual(self.tuner.target_p99_ms, 10.0)
        self.assertEqual(self.tuner.min_recall, 0.95)

    def test_generate_test_data(self):
        """Test synthetic data generation."""
        n_vectors = 1000
        n_queries = 100

        vectors, queries, ground_truth = self.tuner.generate_test_data(
            n_vectors=n_vectors, n_queries=n_queries
        )

        self.assertEqual(vectors.shape, (n_vectors, self.dimension))
        self.assertEqual(queries.shape, (n_queries, self.dimension))
        self.assertEqual(ground_truth.shape, (n_queries, 10))
        self.assertEqual(vectors.dtype, np.float32)
        self.assertEqual(queries.dtype, np.float32)

    @patch("backend.alfred.search.faiss_tuner.faiss")
    def test_build_hnsw_index(self, mock_faiss):
        """Test HNSW index building."""
        mock_index = Mock()
        mock_faiss.IndexHNSWFlat.return_value = mock_index

        vectors = np.random.randn(100, self.dimension).astype("float32")
        m = 16
        ef_construction = 200

        index = self.tuner._build_hnsw_index(vectors, m=m, ef_construction=ef_construction)

        mock_faiss.IndexHNSWFlat.assert_called_once_with(self.dimension, m)
        self.assertEqual(mock_index.hnsw.efConstruction, ef_construction)
        mock_index.add.assert_called_once()
        self.assertEqual(index, mock_index)

    @patch("backend.alfred.search.faiss_tuner.faiss")
    def test_build_opq_hnsw_index(self, mock_faiss):
        """Test OPQ+HNSW index building."""
        mock_opq = Mock()
        mock_pq_index = Mock()
        mock_hnsw_index = Mock()
        mock_combined_index = Mock()

        mock_faiss.OPQMatrix.return_value = mock_opq
        mock_faiss.IndexPQ.return_value = mock_pq_index
        mock_faiss.IndexHNSWFlat.return_value = mock_hnsw_index
        mock_faiss.IndexPreTransform.return_value = mock_combined_index

        vectors = np.random.randn(100, self.dimension).astype("float32")
        m_pq = 8
        n_subquantizers = 32
        m_hnsw = 16
        ef_construction = 200

        index = self.tuner._build_opq_hnsw_index(
            vectors,
            m_pq=m_pq,
            n_subquantizers=n_subquantizers,
            m_hnsw=m_hnsw,
            ef_construction=ef_construction,
        )

        mock_faiss.OPQMatrix.assert_called_once_with(self.dimension, m_pq, n_subquantizers)
        mock_faiss.IndexPQ.assert_called_once_with(self.dimension, m_pq, n_subquantizers)
        mock_faiss.IndexHNSWFlat.assert_called_once_with(self.dimension, m_hnsw)
        mock_faiss.IndexPreTransform.assert_called_once_with(mock_opq, mock_pq_index)

        mock_opq.train.assert_called_once()
        mock_combined_index.add.assert_called_once()
        self.assertEqual(index, mock_combined_index)

    def test_evaluate_index(self):
        """Test index evaluation."""
        # Create mock index
        mock_index = Mock()
        mock_index.ntotal = 1000

        # Mock search results
        n_queries = 10
        retrieved_ids = np.random.randint(0, 1000, (n_queries, 10))
        mock_index.search.return_value = (None, retrieved_ids)

        queries = np.random.randn(n_queries, self.dimension).astype("float32")
        ground_truth = np.random.randint(0, 1000, (n_queries, 10))

        # Make some overlap for non-zero recall
        for i in range(n_queries):
            retrieved_ids[i, :5] = ground_truth[i, :5]

        query_p99_ms, recall_at_10, memory_mb = self.tuner._evaluate_index(
            mock_index, queries, ground_truth, n_runs=10
        )

        self.assertIsInstance(query_p99_ms, float)
        self.assertGreater(query_p99_ms, 0)
        self.assertAlmostEqual(recall_at_10, 0.5, places=2)
        self.assertGreater(memory_mb, 0)

    @patch("backend.alfred.search.faiss_tuner.FAISSTuner._build_hnsw_index")
    @patch("backend.alfred.search.faiss_tuner.FAISSTuner._evaluate_index")
    def test_tune_hnsw(self, mock_evaluate, mock_build):
        """Test HNSW tuning."""
        # Mock index building
        mock_index = Mock()
        mock_build.return_value = mock_index

        # Mock evaluation results
        mock_evaluate.return_value = (5.0, 0.98, 100.0)

        vectors = np.random.randn(100, self.dimension).astype("float32")
        queries = np.random.randn(10, self.dimension).astype("float32")
        ground_truth = np.random.randint(0, 100, (10, 10))

        results = self.tuner.tune_hnsw(vectors, queries, ground_truth)

        self.assertIsInstance(results, list)
        self.assertGreater(len(results), 0)

        # Check first result
        result = results[0]
        self.assertIsInstance(result, TuningResult)
        self.assertEqual(result.index_type, "HNSW")
        self.assertEqual(result.query_p99_ms, 5.0)
        self.assertEqual(result.recall_at_10, 0.98)
        self.assertEqual(result.memory_mb, 100.0)

        # Should have early termination due to meeting targets
        self.assertLess(len(results), 20)

    @patch("backend.alfred.search.faiss_tuner.FAISSTuner._build_opq_hnsw_index")
    @patch("backend.alfred.search.faiss_tuner.FAISSTuner._evaluate_index")
    def test_tune_opq_hnsw(self, mock_evaluate, mock_build):
        """Test OPQ+HNSW tuning."""
        # Mock index building
        mock_index = Mock()
        mock_build.return_value = mock_index

        # Mock evaluation results
        mock_evaluate.return_value = (8.0, 0.96, 50.0)

        vectors = np.random.randn(100, self.dimension).astype("float32")
        queries = np.random.randn(10, self.dimension).astype("float32")
        ground_truth = np.random.randint(0, 100, (10, 10))

        results = self.tuner.tune_opq_hnsw(vectors, queries, ground_truth)

        self.assertIsInstance(results, list)
        self.assertGreater(len(results), 0)

        # Check first result
        result = results[0]
        self.assertIsInstance(result, TuningResult)
        self.assertEqual(result.index_type, "OPQ+HNSW")
        self.assertEqual(result.query_p99_ms, 8.0)
        self.assertEqual(result.recall_at_10, 0.96)
        self.assertEqual(result.memory_mb, 50.0)

    @patch("backend.alfred.search.faiss_tuner.FAISSTuner._build_opq_hnsw_index")
    def test_tune_opq_hnsw_build_failure(self, mock_build):
        """Test OPQ+HNSW tuning with build failure."""
        # Mock index building failure
        mock_build.side_effect = Exception("Build failed")

        vectors = np.random.randn(100, self.dimension).astype("float32")
        queries = np.random.randn(10, self.dimension).astype("float32")
        ground_truth = np.random.randint(0, 100, (10, 10))

        # Should not raise exception, just skip failed configurations
        results = self.tuner.tune_opq_hnsw(vectors, queries, ground_truth)
        self.assertEqual(len(results), 0)

    @patch("backend.alfred.search.faiss_tuner.FAISSTuner.generate_test_data")
    @patch("backend.alfred.search.faiss_tuner.FAISSTuner.tune_hnsw")
    @patch("backend.alfred.search.faiss_tuner.FAISSTuner.tune_opq_hnsw")
    def test_tune(self, mock_tune_opq, mock_tune_hnsw, mock_generate):
        """Test full tuning process."""
        # Mock data generation
        vectors = np.random.randn(100, self.dimension).astype("float32")
        queries = np.random.randn(10, self.dimension).astype("float32")
        ground_truth = np.random.randint(0, 100, (10, 10))
        mock_generate.return_value = (vectors, queries, ground_truth)

        # Mock tuning results
        hnsw_results = [
            TuningResult(
                index_type="HNSW",
                parameters={"m": 16, "ef_search": 64},
                query_p99_ms=9.0,
                recall_at_10=0.97,
                build_time_s=1.0,
                memory_mb=100.0,
            )
        ]
        opq_results = [
            TuningResult(
                index_type="OPQ+HNSW",
                parameters={"m_pq": 8, "n_subquantizers": 32},
                query_p99_ms=8.0,
                recall_at_10=0.96,
                build_time_s=2.0,
                memory_mb=50.0,
            )
        ]

        mock_tune_hnsw.return_value = hnsw_results
        mock_tune_opq.return_value = opq_results

        results = self.tuner.tune(n_vectors=100, n_queries=10)

        self.assertIsInstance(results, dict)
        self.assertIn("HNSW", results)
        self.assertIn("OPQ+HNSW", results)
        self.assertEqual(results["HNSW"], hnsw_results)
        self.assertEqual(results["OPQ+HNSW"], opq_results)

    def test_tuning_result_str(self):
        """Test TuningResult string representation."""
        result = TuningResult(
            index_type="HNSW",
            parameters={"m": 16},
            query_p99_ms=5.5,
            recall_at_10=0.975,
            build_time_s=1.0,
            memory_mb=100.5,
        )

        result_str = str(result)
        self.assertIn("HNSW", result_str)
        self.assertIn("5.50ms", result_str)
        self.assertIn("0.975", result_str)
        self.assertIn("100.5MB", result_str)

    def test_save_results(self):
        """Test saving results to JSON."""
        results = {
            "HNSW": [
                TuningResult(
                    index_type="HNSW",
                    parameters={"m": 16},
                    query_p99_ms=5.0,
                    recall_at_10=0.98,
                    build_time_s=1.0,
                    memory_mb=100.0,
                )
            ]
        }

        with tempfile.NamedTemporaryFile(mode="w", delete=False) as f:
            self.tuner.save_results(results, f.name)

            # Read back and verify
            with open(f.name, "r") as rf:
                loaded_results = json.load(rf)

            self.assertIn("HNSW", loaded_results)
            self.assertEqual(len(loaded_results["HNSW"]), 1)

            hnsw_result = loaded_results["HNSW"][0]
            self.assertEqual(hnsw_result["index_type"], "HNSW")
            self.assertEqual(hnsw_result["query_p99_ms"], 5.0)
            self.assertEqual(hnsw_result["recall_at_10"], 0.98)


if __name__ == "__main__":
    unittest.main()
