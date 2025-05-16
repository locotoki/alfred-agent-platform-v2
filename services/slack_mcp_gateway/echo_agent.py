"""
Echo agent for testing the Slack MCP Gateway integration.

This simple echo agent processes the /alfred ping command and replies with the provided text.
It listens to the MCP request stream and publishes to the response stream.
"""

import json
import logging
import os
import sys
import time
import uuid
from typing import Dict, Any, Optional

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

# Consumer group
ECHO_CONSUMER_GROUP = "echo-agent"
ECHO_CONSUMER_NAME = f"echo-{uuid.uuid4().hex[:8]}"


def get_redis_client() -> redis.Redis:
    """Create and return a Redis client instance."""
    client = redis.Redis(
        host=REDIS_HOST,
        port=REDIS_PORT,
        password=REDIS_PASSWORD,
        db=REDIS_DB,
        decode_responses=True,
    )
    return client


def ensure_consumer_group() -> None:
    """Ensure the consumer group exists for the echo agent."""
    client = get_redis_client()
    
    try:
        # Check if the stream exists already
        client.xinfo_stream(REQUEST_STREAM)
        
        # Check if the consumer group exists, and create if it doesn't
        try:
            client.xinfo_groups(REQUEST_STREAM)
        except redis.exceptions.ResponseError:
            client.xgroup_create(REQUEST_STREAM, ECHO_CONSUMER_GROUP, id="0")
            logger.info(f"Created consumer group {ECHO_CONSUMER_GROUP} for {REQUEST_STREAM}")
    except redis.exceptions.ResponseError:
        # Stream doesn't exist, create it with a dummy message 
        message_id = client.xadd(REQUEST_STREAM, {"init": "true"})
        client.xgroup_create(REQUEST_STREAM, ECHO_CONSUMER_GROUP, id="0")
        logger.info(f"Created stream {REQUEST_STREAM} and consumer group {ECHO_CONSUMER_GROUP}")


def publish_response(response: Dict[str, Any]) -> str:
    """
    Publish a response to the MCP responses stream.
    
    Args:
        response: The response data to publish
        
    Returns:
        The message ID assigned by Redis
    """
    client = get_redis_client()
    
    try:
        # Serialize response to JSON
        response_json = json.dumps(response)
        
        # Add entry to the stream with response as 'data' field
        message_id = client.xadd(
            RESPONSE_STREAM,
            {"data": response_json}
        )
        
        logger.info(f"Published response for request {response['request_id']} to {RESPONSE_STREAM}")
        return message_id
    except Exception as e:
        logger.error(f"Error publishing response to Redis: {e}")
        raise


def process_ping_command(request_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Process a ping command and generate a response.
    
    Args:
        request_data: The request data from Slack
        
    Returns:
        The response data
    """
    try:
        # Extract command text (everything after /alfred ping)
        command_text = request_data.get("text", "")
        
        # Command format: /alfred ping [message]
        # Split by spaces, first part is "ping", rest is the message
        parts = command_text.strip().split(maxsplit=1)
        command = parts[0] if parts else ""
        
        if command.lower() != "ping":
            return {
                "request_id": request_data.get("request_id", "unknown"),
                "channel_id": request_data.get("channel_id"),
                "thread_ts": request_data.get("thread_ts"),
                "text": "❌ Unknown command. Try `/alfred ping [message]`",
                "state": "failed"
            }
        
        # Get the message part (if any)
        message = parts[1] if len(parts) > 1 else "pong!"
        
        # Return the echo response
        return {
            "request_id": request_data.get("request_id", "unknown"),
            "channel_id": request_data.get("channel_id"),
            "thread_ts": request_data.get("thread_ts"),
            "text": f"🏓 {message}",
            "state": "succeeded",
            "type": "echo"
        }
    except Exception as e:
        logger.error(f"Error processing ping command: {e}")
        return {
            "request_id": request_data.get("request_id", "unknown"),
            "channel_id": request_data.get("channel_id"),
            "thread_ts": request_data.get("thread_ts"),
            "text": f"❌ Error processing command: {str(e)}",
            "state": "failed"
        }


def run_echo_agent() -> None:
    """
    Run the echo agent, processing requests from the MCP stream.
    """
    logger.info("Starting echo agent...")
    client = get_redis_client()
    
    # Ensure consumer group exists
    ensure_consumer_group()
    
    # Start reading from the last ID
    last_id = ">"  # Unread messages
    
    try:
        while True:
            try:
                # Read messages from the stream using XREADGROUP
                messages = client.xreadgroup(
                    ECHO_CONSUMER_GROUP,
                    ECHO_CONSUMER_NAME,
                    {REQUEST_STREAM: last_id},
                    count=1,
                    block=5000  # Block for 5 seconds
                )
                
                if not messages:
                    # No messages, continue the loop
                    continue
                
                stream_name, stream_messages = messages[0]
                
                for message_id, fields in stream_messages:
                    # Parse the JSON data
                    if "data" in fields:
                        try:
                            request_data = json.loads(fields["data"])
                            
                            # Acknowledge the message
                            client.xack(REQUEST_STREAM, ECHO_CONSUMER_GROUP, message_id)
                            
                            # Process only if this is a command we can handle
                            # This agent only handles /alfred ping
                            if "command" in request_data and request_data["command"] == "/alfred":
                                command_text = request_data.get("text", "").strip()
                                if command_text.startswith("ping"):
                                    logger.info(f"Processing ping command: {command_text}")
                                    
                                    # Process the ping command
                                    response = process_ping_command(request_data)
                                    
                                    # Publish the response
                                    publish_response(response)
                                else:
                                    logger.info(f"Ignoring non-ping command: {command_text}")
                            
                        except json.JSONDecodeError as e:
                            logger.error(f"Error decoding JSON from message {message_id}: {e}")
                    else:
                        logger.warning(f"Received message {message_id} without data field")
                    
            except redis.exceptions.ConnectionError as e:
                logger.error(f"Redis connection error: {e}")
                time.sleep(5)  # Wait before retrying
                
            except Exception as e:
                logger.error(f"Unexpected error: {e}")
                time.sleep(5)  # Wait before retrying
                
    except KeyboardInterrupt:
        logger.info("Echo agent stopped by user")
        sys.exit(0)


if __name__ == "__main__":
    run_echo_agent()