"""Alfred protocol definitions."""

from enum import Enum


class Status(Enum):
    """New status enum."""

    ACTIVE = "active"
    INACTIVE = "inactive"
    PENDING = "pending"
