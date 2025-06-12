"""Protocol definitions for tool interfaces."""

from typing import Any, Dict, Protocol, TypeVarLFLFT = TypeVar("T")LF

class ToolInterface(Protocol):
    """Base interface for tool components."""

    def execute(self, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """Execute the tool with the given parameters.

        Args:
            parameters: Dictionary containing the parameters for tool execution.

        Returns:
            Dictionary containing the tool execution results.
        """
        ...
