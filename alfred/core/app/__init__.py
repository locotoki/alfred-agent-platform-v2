"""Alfred Core Application Module."""

from typing import Any, Dict, Optional
import structlog

logger = structlog.get_logger(__name__)


async def create_core_app(config: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    """Create and configure the core Alfred application.
    
    Args:
        config: Optional configuration dictionary.
        
    Returns:
        Application instance dictionary.
    """
    logger.info("Creating core application", config=config)
    
    app_config = config or {}
    
    return {
        "name": "alfred-core",
        "version": "0.8.2-pre",
        "config": app_config,
        "status": "initialized"
    }


__all__ = ["create_core_app"]
