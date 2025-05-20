"""Redis message bus for the Slack MCP Gateway.

This module handles publishing task requests to Redis streams and subscribing to
response streams for consumption by the responder.
"""
# type: ignore
import json
import logging
import os
from typing import Any, Dict, Iterator, Tuple

import redis

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Redis connection
REDIS_HOST = os.environ.get("REDIS_HOST", "localhost")
REDIS_PORT = int(os.environ.get("REDIS_PORT", 6379))
REDIS_PASSWORD = os.environ.get("REDIS_PASSWORD", "")
REDIS_DB = int(os.environ.get("REDIS_DB", 0))

# Stream names
REQUEST_STREAM = "mcp.requests"
RESPONSE_STREAM = "mcp.responses"

# Consumer group name
CONSUMER_GROUP = "slack-gw"
CONSUMER_NAME = "slack-responder"


def get_redis_client() -> redis.Redis:
    """Create and return a Redis client instance"""
    client = redis.Redis(
        host=REDIS_HOST,
        port=REDIS_PORT,
        password=REDIS_PASSWORD,
        db=REDIS_DB,
        decode_responses=True,
    )
    return client


def publish(message: Dict[str, Any]) -> str:.
    """Publish a message to the MCP requests stream.

    Args:
        message: The task request to publish

    Returns:
        The message ID assigned by Redis
    """
    client = get_redis_client()

    try:
        # Serialize message to JSON
        message_json = json.dumps(message)

        # Add entry to the stream with message as 'data' field
        message_id = client.xadd(REQUEST_STREAM, {"data": message_json})

        logger.info(f"Published message {message['request_id']} to {REQUEST_STREAM}")
        return message_id
    except Exception as e:
        logger.error(f"Error publishing message to Redis: {e}")
        raise


def ensure_consumer_group() -> None:
    """Ensure the consumer group exists, creating it if necessary"""
    client = get_redis_client()

    try:
        # Check if the stream exists already
        client.xinfo_stream(RESPONSE_STREAM)

        # Check if the consumer group exists, and create if it doesn't
        try:
            client.xinfo_groups(RESPONSE_STREAM)
        except redis.exceptions.ResponseError:
            client.xgroup_create(RESPONSE_STREAM, CONSUMER_GROUP, id="0")
            logger.info(
                f"Created consumer group {CONSUMER_GROUP} for {RESPONSE_STREAM}"
            )
    except redis.exceptions.ResponseError:
        # Stream doesn't exist, create it with a dummy message that we'll discard
        client.xadd(RESPONSE_STREAM, {"init": "true"})
        client.xgroup_create(RESPONSE_STREAM, CONSUMER_GROUP, id="0")
        logger.info(
            f"Created stream {RESPONSE_STREAM} and consumer group {CONSUMER_GROUP}"
        )


def subscribe() -> Iterator[Tuple[str, Dict[str, Any]]]:
    """Subscribe to the MCP responses stream and yield responses.

    Returns:
        An iterator yielding tuples of (message_id, response_data).
    """
    client = get_redis_client()

    # Ensure consumer group exists
    ensure_consumer_group()

    # Start reading from the current last ID
    last_id = ">"

    while True:
        try:
            # Read messages from the stream using XREADGROUP
            messages = client.xreadgroup(
                CONSUMER_GROUP,
                CONSUMER_NAME,
                {RESPONSE_STREAM: last_id},
                count=1,
                block=1000,  # Block for 1 second
            )

            # Process any received messages
            if messages:
                stream_name, stream_messages = messages[0]

                for message_id, fields in stream_messages:
                    # Parse the JSON data
                    if "data" in fields:
                        try:
                            response_data = json.loads(fields["data"])

                            # Acknowledge the message
                            client.xack(RESPONSE_STREAM, CONSUMER_GROUP, message_id)

                            # Yield the parsed message
                            yield message_id, response_data
                        except json.JSONDecodeError as e:
                            logger.error(
                                f"Error decoding JSON from message {message_id}: {e}"
                            )
                    else:
                        logger.warning(
                            f"Received message {message_id} without data field"
                        )
        except redis.exceptions.ConnectionError as e:
            logger.error(f"Redis connection error: {e}")
            # TODO: Implement reconnection logic with backoff
