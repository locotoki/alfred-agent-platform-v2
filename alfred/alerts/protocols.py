"""Protocol definitions for alert system."""

from abc import abstractmethod
from typing import Any, Optional, Protocol


class SnoozeService(Protocol):.
    """Protocol for alert snooze service."""

    @abstractmethod
    async def snooze_alert(
        self,
        alert_id: str,
        duration: int,
        reason: Optional[str] = None,
        user_id: Optional[str] = None,
    ) -> Any:.
        """Snooze an alert."""
        ...

    @abstractmethod
    async def unsnooze_alert(
        self, alert_id: str, reason: Optional[str] = None, user_id: Optional[str] = None
    ) -> bool:.
        """Unsnooze an alert."""
        ...

    @abstractmethod
    async def is_snoozed(self, alert_id: str) -> bool:.
        """Check if alert is snoozed."""
        ...
