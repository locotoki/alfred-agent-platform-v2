"""Alfred model management module."""

from typing import List

from .router.main import create_router_app
from .registry.main import create_registry_app

__all__: List[str] = ["create_router_app", "create_registry_app"]
