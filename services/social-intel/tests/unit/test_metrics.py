"""
Unit tests for the metrics module.
"""

from app.metrics import SI_LATENCY_SECONDS, LatencyTimer
from prometheus_client import REGISTRY


def test_si_latency_seconds_buckets():
    """Test that SI_LATENCY_SECONDS has exactly 6 buckets with correct values."""
    # Get the buckets from the metric
    metric_name = SI_LATENCY_SECONDS._name
    buckets = sorted(
        [
            float(bucket.labels()["le"])
            for bucket in REGISTRY.get_sample_values()
            if bucket.name == f"{metric_name}_bucket" and bucket.labels()["le"] != "+Inf"
        ]
    )

    # Test that there are exactly 6 buckets (excluding +Inf)
    assert len(buckets) == 6, f"Expected 6 buckets, got {len(buckets)}"

    # Test the bucket values
    expected_buckets = [0.05, 0.1, 0.2, 0.4, 0.8, 2]
    assert buckets == expected_buckets, f"Expected buckets {expected_buckets}, got {buckets}"


def test_latency_timer():
    """Test that LatencyTimer records metrics correctly."""
    # Set up a test metric
    test_labels = {"endpoint": "/test"}

    # Use the timer
    with LatencyTimer(SI_LATENCY_SECONDS, test_labels):
        # Just simulate some work
        for i in range(1000):
            pass

    # Check that a sample was recorded (we can't check the exact value)
    samples = [
        s
        for s in REGISTRY.get_sample_values()
        if s.name == f"{SI_LATENCY_SECONDS._name}_count" and s.labels().get("endpoint") == "/test"
    ]

    assert len(samples) > 0, "LatencyTimer did not record any samples"
    assert samples[0].value > 0, "LatencyTimer recorded a count of 0"
