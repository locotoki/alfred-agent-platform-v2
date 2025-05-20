"""Feature flags for the alert system.

This module provides a feature flag system for controlling alert system behavior.
"""

import os
from typing import Dict


class AlertFeatureFlags:
    """Feature flag management for the alert system."""

    @classmethod
    def is_enabled(cls, flag_name: str) -> bool:
        """Check if a feature flag is enabled.

        Feature flags are controlled via environment variables.

        Args:
            flag_name: Name of the feature flag

        Returns:
            True if enabled, False otherwise.
        """
        return os.getenv(flag_name, "false").lower() == "true"

    @classmethod
    def get_config(cls) -> Dict[str, bool]:
        """Get all feature flag configurations.

        Returns:
            Dictionary of feature flags and their states.
        """
        flags = {
            "ALERT_GROUPING_ENABLED": cls.is_grouping_enabled(),
            "ALERT_EXPLAIN_ENABLED": cls.is_explanation_enabled(),
            "ALERT_SNOOZE_ENABLED": cls.is_snooze_enabled(),
            "ALERT_NOTIFY_RESOLVED": cls.is_resolved_notification_enabled(),
        }

        return flags

    @classmethod
    def is_grouping_enabled(cls) -> bool:
        """Check if alert grouping is enabled.

        Returns:
            True if enabled, False otherwise.
        """
        return cls.is_enabled("ALERT_GROUPING_ENABLED")

    @classmethod
    def is_explanation_enabled(cls) -> bool:
        """Check if alert explanation is enabled.

        Returns:
            True if enabled, False otherwise.
        """
        return cls.is_enabled("ALERT_EXPLAIN_ENABLED")

    @classmethod
    def is_snooze_enabled(cls) -> bool:
        """Check if alert snooze functionality is enabled.

        Returns:
            True if enabled, False otherwise.
        """
        return cls.is_enabled("ALERT_SNOOZE_ENABLED")

    @classmethod
    def is_resolved_notification_enabled(cls) -> bool:
        """Check if resolved alert notifications are enabled.

        Returns:
            True if enabled, False otherwise.
        """
        return cls.is_enabled("ALERT_NOTIFY_RESOLVED")

    @classmethod
    def group_by_default(cls) -> bool:
        """Check if alerts should be grouped by default.

        Returns:
            True if alerts should be grouped by default, False otherwise.
        """
        return cls.is_enabled("ALERT_GROUP_BY_DEFAULT")
