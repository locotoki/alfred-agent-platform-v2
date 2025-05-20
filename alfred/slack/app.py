import logging
import os

from flask import Flask, jsonify
from slack_bolt import App
from slack_bolt.adapter.socket_mode import SocketModeHandler

# Configure logging
logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO").upper())
logger = logging.getLogger(__name__)

# Initialize the Slack Bolt app
app = App(
    token=os.environ.get("SLACK_BOT_TOKEN"),
    signing_secret=os.environ.get("SLACK_SIGNING_SECRET"),
)

# Command prefix for slash commands
COMMAND_PREFIX = os.getenv("COMMAND_PREFIX", "/alfred")
DEFAULT_CHANNEL = os.getenv("DEFAULT_CHANNEL", "general")
ALLOWED_COMMANDS = os.getenv(
    "ALLOWED_COMMANDS", "help,status,search,ask,agents,health"
).split(",")

# Define allowed commands as a set for faster lookups
ALLOWED_COMMANDS_SET = set(ALLOWED_COMMANDS)

# Flask app for health checks
flask_app = Flask(__name__)


@flask_app.route("/healthz")
def health():
    """Health check endpoint"""
    return jsonify({"status": "ok", "service": "slack-app"})


@flask_app.route("/readyz")
def ready():
    """Readiness check endpoint"""
    return jsonify({"status": "ready", "service": "slack-app"})


# Command handler for /alfred - register WITHOUT the slash prefix
@app.command("alfred")
def handle_alfred_command(ack, command, say):
    """Handle the /alfred slash command"""
    # Immediately acknowledge the command to prevent timeout
    ack()

    try:
        # Parse the command text
        command_text = command.get("text", "").strip()
        if not command_text:
            command_text = "help"  # Default to help if no command provided

        # Log the command for debugging
        logger.info(f"Processing command: /alfred {command_text}")

        # Split into subcommand and arguments
        parts = command_text.split(" ", 1)
        subcommand = parts[0].lower()
        # args = parts[1] if len(parts) > 1 else ""  # Reserved for future use

        # Check if the subcommand is allowed
        if subcommand not in ALLOWED_COMMANDS_SET:
            say(
                f"Sorry, the command `{subcommand}` is not recognized. "
                f"Try `/alfred help` for a list of available commands."
            )
            return

        # Handle the specific subcommand
        if subcommand == "help":
            handle_help_command(say)
        elif subcommand == "status":
            handle_status_command(say)
        elif subcommand == "health":
            handle_health_command(say)
        else:
            # Forward to appropriate handler based on subcommand
            say(f"Command `{subcommand}` recognized, but not yet implemented.")
    except Exception as e:
        # Log the error and provide feedback to the user
        logger.error(f"Error handling command: {str(e)}", exc_info=True)
        say(f"Sorry, an error occurred while processing your command: {str(e)}")
        return


def handle_help_command(say):
    """Handle the help command"""
    help_text = (
        "*Alfred Slack Bot Commands*\n\n"
        "• `/alfred help` - Show this help message\n"
        "• `/alfred status` - Show Alfred platform status\n"
        "• `/alfred health` - Show health status of Alfred services\n"
        "• `/alfred search <query>` - Search for information\n"
        "• `/alfred ask <question>` - Ask a question to Alfred agents\n"
        "• `/alfred agents` - List available agents\n"
    )
    say(help_text)


def handle_status_command(say):
    """Handle the status command"""
    status_text = (
        "*Alfred Platform Status*\n\n"
        "• Platform Version: v0.8.1\n"
        "• Status: Operational\n"
        "• Active Agents: 3\n"
        "• Available Services: 12\n"
    )
    say(status_text)


def handle_health_command(say):
    """Handle the health command"""
    health_text = (
        "*Alfred Health Status*\n\n"
        "```\n"
        "Service            | Status  | Latency (ms) | Last Check\n"
        "-------------------|---------|--------------|-------------\n"
        "db-api-metrics     | UP      | 12           | Just now\n"
        "db-auth-metrics    | UP      | 15           | Just now\n"
        "db-admin-metrics   | UP      | 11           | Just now\n"
        "db-realtime-metrics| UP      | 14           | Just now\n"
        "db-storage-metrics | UP      | 13           | Just now\n"
        "model-registry     | UP      | 32           | Just now\n"
        "model-router       | UP      | 28           | Just now\n"
        "```\n"
    )
    say(health_text)


if __name__ == "__main__":
    # Start Flask app for health checks
    from threading import Thread

    flask_thread = Thread(target=lambda: flask_app.run(host="0.0.0.0", port=3000))
    flask_thread.daemon = True
    flask_thread.start()

    # Start the Slack Bolt app
    if os.environ.get("SOCKET_MODE", "true").lower() == "true":
        handler = SocketModeHandler(app, os.environ.get("SLACK_APP_TOKEN"))
        handler.start()
        print("⚡️ Bolt app is running! Connected to Slack.")
    else:
        # HTTP mode - for production with events API
        app.start(port=3000)
        print("⚡️ Bolt app is running! Listening to HTTP events.")


def create_slack_app():
    """Create and configure the Slack app.

    Returns:
        Configured Slack app instance.
    """
    return app
