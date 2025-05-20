"""Responder module for processing MCP responses and updating Slack threads.

This module runs a background asyncio task to consume responses from
Redis and update the corresponding Slack thread using the chat.update
API.
"""

import asyncio
import json
import logging
import os
import socket
from typing import Any, Dict, Optional, Set

import redis
import redis_bus  # Changed from relative import
from slack_sdk import WebClient
from slack_sdk.errors import SlackApiError

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Get hostname for consumer ID
HOSTNAME = os.environ.get("HOSTNAME", socket.gethostname())


class ResponseHandler:
    """Handler for MCP responses that updates Slack threads."""

    def __init__(self, slack_token: str):
        """Initialize the response handler.

        Args:
            slack_token: The Slack bot token for API calls

        """
        self.client = WebClient(token=slack_token)
        self.stop_event = asyncio.Event()
        self.task = None
        self.in_flight: Set[str] = set()  # Track request_ids of in-flight requests

    def add_in_flight(self, request_id: str) -> None:
        """Add a request_id to the in-flight set.

        Args:
            request_id: The request ID to track

        """
        self.in_flight.add(request_id)
        # Trim the set if it gets too large (unlikely, but a safeguard)
        if len(self.in_flight) > 1000:
            # Keep the 500 most recent (assuming they're added in order)
            self.in_flight = set(list(self.in_flight)[-500:])

    async def start(self) -> None:
        """Start the response handler as an asyncio task."""
        if self.task is None or self.task.done():
            self.stop_event.clear()
            self.task = asyncio.create_task(self._response_loop())
            logger.info("Started response handler task")

    async def stop(self) -> None:
        """Stop the response handler task."""
        self.stop_event.set()
        if self.task and not self.task.done():
            await self.task
            logger.info("Stopped response handler task")

    async def _response_loop(self) -> None:
        """Process responses from Redis in a continuous loop."""
        logger.info("Response handler task started")

        # Use the stream, group, and consumer ID as specified
        async for message_id, response in self._subscribe_async(
            stream="mcp.responses", group="slack-gw", consumer_id=HOSTNAME
        ):
            if await self.stop_event.is_set():
                break

            try:
                # Extract the request_id
                request_id = response.get("request_id")

                # Skip if not in our in-flight set
                if request_id not in self.in_flight:
                    logger.info(
                        f"Ignoring unrelated response for request_id: {request_id}"
                    )
                    continue

                # Set request_id in logger context
                with logging.LoggerAdapter(logger, {"request_id": request_id}):
                    await self._process_response(response, message_id)

                    # Remove from in-flight set after processing
                    self.in_flight.discard(request_id)

            except Exception as e:
                logger.error(f"Error processing response {message_id}: {e}")

    async def _subscribe_async(self, stream, group, consumer_id):
        """Async wrapper around redis_bus.subscribe() that works with asyncio.

        Args:
            stream: The Redis stream to subscribe to
            group: The consumer group name
            consumer_id: The consumer ID (usually the hostname)

        Yields:
            Tuples of (message_id, response_data).

        """
        # We'll use an executor to run the blocking Redis operations
        loop = asyncio.get_event_loop()

        while not await self.stop_event.is_set():
            try:
                # Create a Redis connection for subscription
                client = redis_bus.get_redis_client()

                # Ensure the consumer group exists
                redis_bus.ensure_consumer_group()

                # Read messages with XREADGROUP
                last_id = ">"  # Start with unread messages

                while not await self.stop_event.is_set():
                    # Run the blocking Redis read in the executor pool
                    messages = await loop.run_in_executor(
                        None,
                        lambda: client.xreadgroup(
                            group,
                            consumer_id,
                            {stream: last_id},
                            count=1,
                            block=1000,  # Block for 1 second
                        ),
                    )

                    # Process any received messages
                    if messages:
                        stream_name, stream_messages = messages[0]

                        for message_id, fields in stream_messages:
                            # Parse the JSON data
                            if "data" in fields:
                                try:
                                    response_data = json.loads(fields["data"])

                                    # Yield the parsed message
                                    yield message_id, response_data

                                    # After successful processing, acknowledge the message
                                    await loop.run_in_executor(
                                        None,
                                        lambda: client.xack(stream, group, message_id),
                                    )

                                except json.JSONDecodeError as e:
                                    logger.error(
                                        f"Error decoding JSON from message {message_id}: {e}"
                                    )
                            else:
                                logger.warning(
                                    f"Received message {message_id} without data field"
                                )

                    # Allow other tasks to run
                    await asyncio.sleep(0)

            except redis.exceptions.ConnectionError as e:
                logger.error(f"Redis connection error: {e}")
                # Implement reconnection with backoff
                await asyncio.sleep(5)

            except Exception as e:
                logger.error(f"Unexpected error in subscription: {e}")
                await asyncio.sleep(5)

    async def _process_response(
        self, response: Dict[str, Any], message_id: str
    ) -> None:
        """Process a response and update the corresponding Slack thread.

        Args:
            response: The response data from MCP
            message_id: The Redis message ID.

        """
        # Extract relevant fields from the response
        request_id = response.get("request_id")
        logger.info(f"Processing response for request_id: {request_id}")

        # Get channel and thread info
        channel_id = response.get("channel_id")
        thread_ts = response.get("thread_ts")

        # Extract message content
        text = response.get("text", "Command processing completed.")
        blocks = self._render_to_slack(response)

        if not channel_id:
            logger.error(f"Response lacks channel_id: {response}")
            return

        # Update the thread with the response
        try:
            # Run the Slack API call in the default executor
            loop = asyncio.get_event_loop()

            # Use chat_update if thread_ts is available, otherwise post a new message
            if thread_ts:
                await loop.run_in_executor(
                    None,
                    lambda: self.client.chat_update(
                        channel=channel_id,
                        ts=thread_ts,
                        text=text,
                        blocks=blocks if blocks else None,
                    ),
                )
                logger.info(f"Updated Slack thread {thread_ts} in channel {channel_id}")
            else:
                await loop.run_in_executor(
                    None,
                    lambda: self.client.chat_postMessage(
                        channel=channel_id, text=text, blocks=blocks if blocks else None
                    ),
                )
                logger.info(f"Posted new message to channel {channel_id}")

        except SlackApiError as e:
            logger.error(f"Slack API error: {e.response['error']}")

    def _render_to_slack(self, response: Dict[str, Any]) -> Optional[list]:
        """Render response to Slack blocks format.

        Args:
            response: The response data

        Returns:
            List of Slack blocks or None if no blocks could be created.

        """
        try:
            # Extract response data
            text = response.get("text", "")
            state = response.get("state", "unknown")
            task_type = response.get("type", "unknown")

            # State mapping for visual reference in comments
            # "succeeded": "#36a64f" (Green)
            # "failed": "#dc3545" (Red)
            # "in_progress": "#ffc107" (Yellow)
            # default: "#6c757d" (Gray)

            # Create blocks for a nicer display
            blocks = [
                {"type": "section", "text": {"type": "mrkdwn", "text": f"*{text}*"}},
                {
                    "type": "context",
                    "elements": [
                        {
                            "type": "mrkdwn",
                            "text": f"Status: `{state}` • Type: `{task_type}`",
                        }
                    ],
                },
            ]

            # Add any additional data as fields
            details = []
            for key, value in response.items():
                if key not in [
                    "text",
                    "state",
                    "type",
                    "request_id",
                    "channel_id",
                    "thread_ts",
                ]:
                    # Format based on type
                    if isinstance(value, dict):
                        value_text = json.dumps(value, indent=2)
                    elif isinstance(value, list):
                        value_text = json.dumps(value)
                    else:
                        value_text = str(value)

                    details.append(f"*{key}*: `{value_text}`")

            # Add details if available
            if details:
                blocks.append(
                    {
                        "type": "section",
                        "fields": [
                            {
                                "type": "mrkdwn",
                                "text": "\n".join(
                                    details[:10]
                                ),  # Limit to avoid overflow
                            }
                        ],
                    }
                )

            return blocks
        except Exception as e:
            logger.error(f"Error rendering Slack blocks: {e}")
            return None
