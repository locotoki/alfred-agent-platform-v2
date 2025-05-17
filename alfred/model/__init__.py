"""Alfred model management module."""

from .router.main import create_router_app
from .registry.main import create_registry_app

__all__ = ["create_router_app", "create_registry_app"]