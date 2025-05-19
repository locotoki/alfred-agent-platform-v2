"""Alfred Slack integration module.

Legacy import shims — **TO BE REMOVED 2025-07-01**.
"""

import importlib
import sys
from typing import TYPE_CHECKING, List

from .diagnostics import DiagnosticsBot

if TYPE_CHECKING:
    from .app import create_slack_app

__all__: List[str] = ["DiagnosticsBot", "create_slack_app"]

# Legacy import shims
shims = {
    "services.slack_app":         "alfred.slack.app",
    "services.slack_diagnostics": "alfred.slack.diagnostics",
    "services.slack_mcp_gateway": "alfred.slack.mcp_gateway",
}
for old, new in shims.items():
    sys.modules[old] = importlib.import_module(new)
