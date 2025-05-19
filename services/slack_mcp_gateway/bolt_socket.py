"""
Slack Bolt Socket Mode listener for the MCP Gateway.

This module handles interactions with the Slack API using Socket Mode,
acknowledges slash commands, and forwards requests to Redis via the translator.
"""

import logging
import os
from typing import Any, Callable, Dict

from slack_bolt import App
from slack_bolt.adapter.socket_mode import SocketModeHandler

from . import redis_bus, responder, translator

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)


def create_app() -> App:
    """Create and configure a Slack Bolt app."""
    # Fetch Slack tokens from environment
    slack_bot_token = os.environ.get("SLACK_BOT_TOKEN")
    if not slack_bot_token:
        raise ValueError("SLACK_BOT_TOKEN environment variable is required")

    slack_signing_secret = os.environ.get("SLACK_SIGNING_SECRET")
    if not slack_signing_secret:
        raise ValueError("SLACK_SIGNING_SECRET environment variable is required")

    app = App(
        token=slack_bot_token,
        signing_secret=slack_signing_secret,
    )

    # Create response handler
    response_handler = responder.ResponseHandler(slack_bot_token)

    # Start the response handler
    response_handler.start()

    # Register the alfred command handler
    @app.command("/alfred")
    def handle_alfred_command(ack: Callable, command: Dict[str, Any]) -> None:
        """
        Handle the /alfred slash command.

        Args:
            ack: Function to acknowledge the command request
            command: The command data from Slack
        """
        # Immediately acknowledge the command to avoid timeout
        ack({"text": "Processing your request..."})

        try:
            # Convert the Slack payload to a task request
            task_request = translator.build_task_request(command)

            # Add the request_id to the in-flight set for the response handler
            request_id = task_request.get("request_id")  # noqa: F841

            # Publish the request to Redis
            redis_bus.publish(task_request)

            logger.info(
                f"Processed alfred command '{task_request.get('text', '')}' from user {command['user_id']}"
            )
        except Exception as e:
            logger.error(f"Error processing alfred command: {e}")

    return app


def start_socket_mode() -> None:
    """
    Start the Socket Mode handler for real-time Slack events.
    """
    # Get the app token from environment
    slack_app_token = os.environ.get("SLACK_APP_TOKEN")
    if not slack_app_token:
        raise ValueError("SLACK_APP_TOKEN environment variable is required")

    try:
        app = create_app()

        # Start the Socket Mode handler
        handler = SocketModeHandler(app=app, app_token=slack_app_token)

        logger.info("Starting Slack MCP Gateway in Socket Mode")
        handler.start()
    except Exception as e:
        logger.error(f"Failed to start Socket Mode handler: {e}")
        raise


if __name__ == "__main__":
    start_socket_mode()
