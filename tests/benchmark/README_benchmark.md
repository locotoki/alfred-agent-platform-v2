# Benchmark Tests

This directory contains performance benchmark tests that require special environment setup to run properly. These tests are skipped by default in CI pipelines.

## Purpose

The benchmark tests measure performance characteristics of various components:
- ML model inference speed
- Database operation latency
- API response times
- Resource utilization

## Running Benchmarks

To run benchmark tests, you need to use both the `--run-benchmark` flag and the `-m benchmark` marker:

```bash
# Run all benchmark tests
pytest --run-benchmark -m benchmark

# Run a specific benchmark test with verbose output
pytest tests/benchmark/specific_test.py -v --run-benchmark -m benchmark
```

Without the `--run-benchmark` flag, the tests will be skipped with a message indicating they require a controlled environment.

## Requirements

Benchmark tests need a controlled environment:

1. Dedicated hardware with consistent performance
2. Required dependencies for ML benchmarks:
   - `sentence_transformers`
   - `faiss-cpu` or `faiss-gpu`
   - Sufficient memory and CPU/GPU resources
3. Database benchmark requirements:
   - Clean database with predictable state
   - Database with sufficient resources
   - No other competing operations

## Results

Benchmark results should be compared against baseline measurements established in the controlled environment. Results from different environments are not directly comparable due to hardware and configuration differences.

## Adding New Benchmarks

When adding new benchmark tests:
1. Add the `@pytest.mark.benchmark` marker to the test function
2. Document hardware requirements
3. Add proper cleanup to avoid test interference

Example:

```python
import pytest

@pytest.mark.benchmark
def test_model_inference_speed():
    """Benchmark model inference speed.

    Requirements:
    - 16GB+ RAM
    - GPU with 8GB+ VRAM
    - sentence_transformers package
    """
    # Test implementation
    assert performance_metric < threshold
```
