"""Tests for FAISS performance tuning results."""

import re
from pathlib import Path


def test_p99_latency_under_target():
    """Ensure P99 latency for HNSW index is under 0.01 seconds based on benchmark results."""
    md_path = Path(__file__).resolve().parents[3] / "benchmarks" / "faiss" / "results_2025-05-18.md"
    text = md_path.read_text().splitlines()

    # Locate header to find P99 column index
    header = next(line for line in text if line.startswith("| Index Type"))
    columns = [col.strip() for col in header.strip("|").split("|")]
    p99_idx = columns.index("P99 Latency (ms)")

    # Find the HNSW row
    hnsw_line = next(line for line in text if line.startswith("| HNSW"))
    values = [val.strip() for val in hnsw_line.strip("|").split("|")]
    p99_ms = float(values[p99_idx])

    # Convert milliseconds to seconds and assert threshold
    p99_sec = p99_ms / 1000.0
    assert p99_sec < 0.01, f"P99 latency {p99_sec}s exceeds threshold of 0.01s"
