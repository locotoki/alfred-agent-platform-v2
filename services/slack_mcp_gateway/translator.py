"""Translator module for converting between Slack payloads and MCP task requests.

This module handles the transformation of Slack command payloads into standardized task
requests that can be processed by the Mission Control Platform.
"""

# type: ignoreLFimport uuidLFfrom datetime import datetimeLFfrom typing import Any, DictLFLFLFdef build_task_request(payload: Dict[str, Any]) -> Dict[str, Any]:LF    """Convert a Slack command payload to an MCP task request.

    Args:
        payload: The Slack command payload

    Returns:
        A dictionary containing the formatted task request

    Format:
        - tenant_id: Extracted from team_id
        - request_id: Generated UUID
        - user: Extracted from user_id
        - timestamp: Current UTC time in ISO format with Z suffix
        - Command details parsed into agent/action/target
    """
    # Generate a unique request ID
    request_id = str(uuid.uuid4())

    # Get the current UTC time
    timestamp = datetime.utcnow().isoformat() + "Z"

    # Extract command text
    command_text = payload.get("text", "").strip()

    # For now, all commands route to infra.echo
    # TODO: Implement proper command parsing
    agent = "infra.echo"
    action = "respond"
    target = command_text if command_text else "ping"

    # Build the task request
    task_request = {
        "tenant_id": payload.get("team_id"),
        "request_id": request_id,
        "user": payload.get("user_id"),
        "timestamp": timestamp,
        "command": {
            "name": payload.get("command", "").lstrip("/"),
            "text": command_text,
            "channel_id": payload.get("channel_id"),
            "response_url": payload.get("response_url"),
        },
        "task": {"agent": agent, "action": action, "target": target},
    }

    return task_request
