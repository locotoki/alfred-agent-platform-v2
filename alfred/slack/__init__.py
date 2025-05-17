"""Alfred Slack integration module."""

from typing import List, TYPE_CHECKING

if TYPE_CHECKING:
    from .app import create_slack_app

from .diagnostics import DiagnosticsBot

__all__: List[str] = ["DiagnosticsBot", "create_slack_app"]
