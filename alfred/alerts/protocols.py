"""Protocol definitions for alert system"""
from abc import abstractmethod
from datetime import datetime
from typing import Any, Dict, Optional, Protocol, List


class AlertProtocol(Protocol):
    """Protocol for alert entities"""
    
    @property
    def id(self) -> str:
        """Get alert ID"""
        ...
        
    @property
    def service(self) -> str:
        """Get service name"""
        ...
        
    @property
    def severity(self) -> str:
        """Get alert severity"""
        ...
        
    @property
    def timestamp(self) -> datetime:
        """Get alert timestamp"""
        ...
        
    @property
    def message(self) -> str:
        """Get alert message"""
        ...
        
    @property
    def details(self) -> Dict[str, Any]:
        """Get alert details"""
        ...


class SnoozeService(Protocol):
    """Protocol for alert snooze service"""

    @abstractmethod
    async def snooze_alert(
        self,
        alert_id: str,
        duration: int,
        reason: Optional[str] = None,
        user_id: Optional[str] = None,
    ) -> Any:
        """Snooze an alert"""
        ...

    @abstractmethod
    async def unsnooze_alert(
        self, alert_id: str, reason: Optional[str] = None, user_id: Optional[str] = None
    ) -> bool:
        """Unsnooze an alert"""
        ...

    @abstractmethod
    async def is_snoozed(self, alert_id: str) -> bool:
        """Check if alert is snoozed"""
        ...
