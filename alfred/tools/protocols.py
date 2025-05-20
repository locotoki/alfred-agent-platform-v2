"""Protocol definitions for tool interfaces."""

from typing import Any, Dict, Protocol, TypeVar

T = TypeVar("T")


class ToolInterface(Protocol):
    """Base interface for tool components."""

    def execute(self, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """Execute the tool with the given parameters."""
        ...
