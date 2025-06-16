#!/usr/bin/env python3
"""
Minimal Slack bot with Socket Mode
"""
import logging
import os
from threading import Thread

from flask import Flask, jsonify
from slack_bolt import App
from slack_bolt.adapter.socket_mode import SocketModeHandler

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Initialize the app
app = App(
    token=os.environ.get("SLACK_BOT_TOKEN"), signing_secret=os.environ.get("SLACK_SIGNING_SECRET")
)


# Middleware to log all events
@app.middleware
def log_request(logger, body, next):
    logger.debug(f"Received event: {body}")
    return next()


# Listen for /alfred command
@app.command("/alfred")
def handle_alfred_command(ack, command, logger, respond):
    logger.info(f"Handling /alfred command with text: {command.get('text')}")
    ack()
    text = command.get("text", "").lower()

    try:
        if text == "ping":
            logger.info("Sending Pong response")
            respond("Pong! 🏓")
        else:
            logger.info(f"Sending general response for: {text}")
            respond(f"Alfred received: {text}")
    except Exception as e:
        logger.error(f"Error responding: {e}")
        respond("Sorry, something went wrong!")


# Health check endpoint
@app.event("app_mention")
def handle_app_mention(event, say):
    say(f"Hi <@{event['user']}>! I'm Alfred.")


# Create Flask app for health check
flask_app = Flask(__name__)


@flask_app.route("/health")
def health():
    return jsonify({"status": "healthy", "service": "slack-bot"}), 200


def run_flask():
    flask_app.run(host="0.0.0.0", port=8000)


if __name__ == "__main__":
    # Start Flask in a separate thread for health checks
    flask_thread = Thread(target=run_flask, daemon=True)
    flask_thread.start()

    # Start Socket Mode
    handler = SocketModeHandler(app, os.environ.get("SLACK_APP_TOKEN"))
    logger.info("⚡️ Slack bot is running in Socket Mode!")
    handler.start()
