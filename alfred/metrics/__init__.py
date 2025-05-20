"""Alfred metrics collection module"""
# type: ignore
# The db_metrics module provides the Flask app directly
from .db_metrics import app as db_metrics_app

__all__ = ["db_metrics_app"]
