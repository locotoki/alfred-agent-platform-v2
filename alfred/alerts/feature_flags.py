"""Feature flags for alert system features."""

import os
from typing import Dict, Any

class AlertFeatureFlags:
    """Manage feature flags for alert system."""
    
    ALERT_GROUPING_ENABLED = "ALERT_GROUPING_ENABLED"
    
    @classmethod
    def is_enabled(cls, flag_name: str) -> bool:
        """Check if a feature flag is enabled.
        
        Args:
            flag_name: Name of the feature flag
            
        Returns:
            True if enabled, False otherwise
        """
        return os.getenv(flag_name, "false").lower() == "true"
    
    @classmethod
    def get_config(cls) -> Dict[str, bool]:
        """Get all feature flag configurations.
        
        Returns:
            Dictionary of feature flags and their states
        """
        return {
            cls.ALERT_GROUPING_ENABLED: cls.is_enabled(cls.ALERT_GROUPING_ENABLED)
        }