import logging
import os

from flask import Flask, jsonify, request

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@app.route("/")
def home():
    return "Slack Bot is running"


@app.route("/healthz")
def healthz():
    return jsonify({"status": "healthy"})


@app.route("/api/events", methods=["POST"])
def slack_events():
    data = request.json
    logger.info(f"Received event: {data}")

    # Simple echo response
    return jsonify(
        {
            "version": "1.0",
            "message_id": "123e4567-e89b-12d3-a456-426614174000",
            "timestamp": "2023-04-28T14:30:00Z",
            "source": "slack-bot",
            "destination": "user",
            "payload": {
                "text": f"Echo: {data.get('event', {}).get('text', 'No text')}"
            },
        }
    )


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8011))
    logger.info(f"Starting Slack Bot on port {port}")
    logger.info(
        f"Using Slack token: {os.environ.get('SLACK_BOT_TOKEN', 'Not set')[0:5]}..."
    )
    app.run(host="0.0.0.0", port=port)
