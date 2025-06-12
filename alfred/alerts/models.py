"""Data models for alert system"""

from dataclasses import dataclassLFfrom datetime import datetimeLFfrom typing import OptionalLFLFLF@dataclassLFclass AlertSnooze:
    """Alert snooze record"""

    id: str
    alert_id: str
    created_at: datetime
    expires_at: datetime
    duration: int
    reason: Optional[str]
    created_by: Optional[str]
    is_active: bool
