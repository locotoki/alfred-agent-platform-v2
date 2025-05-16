"""
Slack Bolt Socket Mode listener for the MCP Gateway.

This module handles interactions with the Slack API using Socket Mode,
acknowledges slash commands, and forwards requests to Redis via the translator.
"""
import logging
import os
from typing import Callable, Dict, Any

from slack_bolt import App
from slack_bolt.adapter.socket_mode import SocketModeHandler

from . import translator, redis_bus

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)


def create_app() -> App:
    """Create and configure a Slack Bolt app."""
    app = App(
        token=os.environ.get("SLACK_BOT_TOKEN"),
        signing_secret=os.environ.get("SLACK_SIGNING_SECRET"),
    )

    # Register the ping command handler
    @app.command("/ping")
    def handle_ping_command(ack: Callable, command: Dict[str, Any]) -> None:
        """
        Handle the /ping slash command.
        
        Args:
            ack: Function to acknowledge the command request
            command: The command data from Slack
        """
        # Acknowledge the command within 3 seconds
        ack()
        
        try:
            # Convert the Slack payload to a task request
            task_request = translator.build_task_request(command)
            
            # Publish the request to Redis
            redis_bus.publish(task_request)
            
            logger.info(f"Processed ping command from user {command['user_id']}")
        except Exception as e:
            logger.error(f"Error processing ping command: {e}")
    
    return app


def start_socket_mode() -> None:
    """
    Start the Socket Mode handler for real-time Slack events.
    """
    app = create_app()
    
    # Start the Socket Mode handler
    handler = SocketModeHandler(
        app=app,
        app_token=os.environ.get("SLACK_APP_TOKEN")
    )
    
    logger.info("Starting Slack MCP Gateway in Socket Mode")
    handler.start()


if __name__ == "__main__":
    start_socket_mode()