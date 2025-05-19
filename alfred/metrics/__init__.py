"""Observability stack (Prometheus, Grafana, exporters).

Legacy import shims — REMOVE BY 2025-07-01
"""

import importlib
import sys

# The db_metrics module provides the Flask app directly
from .db_metrics import app as db_metrics_app

__all__ = ["db_metrics_app"]

# Legacy import shims
for o, n in {
    "services.metrics.prometheus":      "alfred.metrics.prometheus",
    "services.metrics.grafana":         "alfred.metrics.grafana",
    "services.metrics.redis_exporter":  "alfred.metrics.redis_exporter",
}.items():
    sys.modules[o] = importlib.import_module(n)
