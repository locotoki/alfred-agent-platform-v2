"""API routes for the Alfred platform"""
# type: ignore
from .alert_snooze import router as alert_snooze_router
from .thresholds import router as thresholds_router

__all__ = ["alert_snooze_router", "thresholds_router"]
