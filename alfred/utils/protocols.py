"""Protocol definitions for utility interfaces."""

from typing import Any, Dict, Protocol, TypeVar

T = TypeVar("T")


class UtilityInterface(Protocol):
    """Base interface for utility components."""

    def process(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Process input data and return results."""
        ...
