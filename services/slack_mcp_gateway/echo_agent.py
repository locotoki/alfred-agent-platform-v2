#!/usr/bin/env python3
"""Fixed echo agent for testing the Slack MCP Gateway integration."""

import json
import logging
import os
import sys
import time
import uuid
from typing import Any, Dict

import redis

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# Redis connection
REDIS_URL = os.environ.get("REDIS_URL", "redis://localhost:6379")
REDIS_PASSWORD = os.environ.get("REDIS_PASSWORD", "")

# Stream names
REQUEST_STREAM = "mcp.requests"
RESPONSE_STREAM = "mcp.responses"

# Consumer group
ECHO_CONSUMER_GROUP = "echo-agent"
ECHO_CONSUMER_NAME = f"echo-{uuid.uuid4().hex[:8]}"


def get_redis_client() -> redis.Redis:
    """Create and return a Redis client instance"""
    # Parse Redis URL if provided
    if REDIS_URL.startswith("redis://"):
        return redis.from_url(REDIS_URL, decode_responses=True)
    else:
        # Fallback to individual params
        return redis.Redis(
            host=os.environ.get("REDIS_HOST", "localhost"),
            port=int(os.environ.get("REDIS_PORT", 6379)),
            password=REDIS_PASSWORD,
            db=int(os.environ.get("REDIS_DB", 0)),
            decode_responses=True,
        )


def ensure_consumer_group(client: redis.Redis) -> None:
    """Ensure the consumer group exists for the echo agent"""
    try:
        # Try to create the consumer group
        client.xgroup_create(REQUEST_STREAM, ECHO_CONSUMER_GROUP, id="0", mkstream=True)
        logger.info(f"Created consumer group {ECHO_CONSUMER_GROUP}")
    except redis.ResponseError as e:
        if "BUSYGROUP" in str(e):
            logger.info(f"Consumer group {ECHO_CONSUMER_GROUP} already exists")
        else:
            raise


def process_command(request_data: Dict[str, Any]) -> Dict[str, Any]:
    """Process a command and generate a response."""
    command_text = request_data.get("text", "").strip()

    if command_text.startswith("ping"):
        # Extract the text after "ping"
        ping_text = command_text[4:].strip() or "pong"
        response_text = f"🏓 {ping_text}"
    elif command_text == "health":
        response_text = "✅ Echo agent is healthy and responding to commands!"
    else:
        response_text = f"Echo agent received: {command_text}"

    return {
        "request_id": request_data.get("id", request_data.get("request_id")),
        "text": response_text,
    }


def run_echo_agent():
    """Main loop for the echo agent"""
    logger.info("Starting fixed echo agent...")

    client = get_redis_client()

    # Test connection
    try:
        client.ping()
        logger.info("Successfully connected to Redis")
    except Exception as e:
        logger.error(f"Failed to connect to Redis: {e}")
        sys.exit(1)

    # Ensure consumer group exists
    ensure_consumer_group(client)

    logger.info(f"Echo agent ready. Listening on {REQUEST_STREAM} as {ECHO_CONSUMER_NAME}")

    while True:
        try:
            # Read messages from the stream
            messages = client.xreadgroup(
                ECHO_CONSUMER_GROUP,
                ECHO_CONSUMER_NAME,
                {REQUEST_STREAM: ">"},
                count=1,
                block=5000,  # Block for 5 seconds
            )

            if not messages:
                continue

            for stream_name, stream_messages in messages:
                for message_id, fields in stream_messages:
                    try:
                        # Check if data is in a 'data' field (JSON) or direct fields
                        if "data" in fields:
                            # JSON format
                            request_data = json.loads(fields.get("data", "{}"))
                        else:
                            # Direct fields format (from slack_mcp_gateway)
                            request_data = fields

                        # Log the received command
                        logger.info(
                            f"Processing command: {request_data.get('command')} {request_data.get('text')}"
                        )

                        # Process the command
                        response = process_command(request_data)

                        # Publish the response
                        response_json = json.dumps(response)
                        client.xadd(RESPONSE_STREAM, {"data": response_json})

                        logger.info(f"Published response for request {response['request_id']}")

                        # Acknowledge the message
                        client.xack(REQUEST_STREAM, ECHO_CONSUMER_GROUP, message_id)

                    except Exception as e:
                        logger.error(f"Error processing message {message_id}: {e}")
                        # Still acknowledge to prevent reprocessing
                        client.xack(REQUEST_STREAM, ECHO_CONSUMER_GROUP, message_id)

        except KeyboardInterrupt:
            logger.info("Echo agent stopped by user")
            break
        except Exception as e:
            logger.error(f"Unexpected error: {e}")
            time.sleep(5)


if __name__ == "__main__":
    run_echo_agent()
