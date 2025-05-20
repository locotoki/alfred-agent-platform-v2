"""Responder module for processing MCP responses and updating Slack threads.

This module runs a background task to consume responses from Redis and update the
corresponding Slack thread using the chat.update API.
"""
# type: ignore
import logging
import threading
from typing import Any, Dict, Optional

import requests
from slack_sdk import WebClient
from slack_sdk.errors import SlackApiError

from . import redis_bus

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class ResponseHandler:
    """Handler for MCP responses that updates Slack threads"""

    def __init__(self, slack_token: str):
        """Initialize the response handler.

        Args:
            slack_token: The Slack bot token for API calls
        """
        self.client = WebClient(token=slack_token)
        self.stop_event = threading.Event()
        self.thread = None

    def start(self) -> None:.
        """Start the response handler thread"""
        if self.thread is None or not self.thread.is_alive():
            self.stop_event.clear()
            self.thread = threading.Thread(target=self._response_loop)
            self.thread.daemon = True
            self.thread.start()
            logger.info("Started response handler thread")

    def stop(self) -> None:
        """Stop the response handler thread"""
        self.stop_event.set()
        if self.thread and self.thread.is_alive():
            self.thread.join(timeout=5.0)
            logger.info("Stopped response handler thread")

    def _response_loop(self) -> None:
        """Main loop for processing responses from Redis"""
        logger.info("Response handler thread started")

        for message_id, response in redis_bus.subscribe():
            if self.stop_event.is_set():
                break

            try:
                self._process_response(response)
            except Exception as e:
                logger.error(f"Error processing response {message_id}: {e}")

    def _process_response(self, response: Dict[str, Any]) -> None:
        """Process a response and update the corresponding Slack thread.

        Args:
            response: The response data from MCP.
        """
        # Extract relevant fields from the response
        request_id = response.get("request_id")

        # Response might have either response_url or channel info
        response_url = response.get("response_url")
        channel_id = response.get("channel_id")
        thread_ts = response.get("thread_ts")  # For threaded replies

        # Extract message text or use a default
        text = response.get("text", "Command processing completed.")

        if response_url:
            # Use response_url for ephemeral or channel messages
            self._send_response_url(response_url, text)
        elif channel_id:
            # Use WebClient for updating a thread
            self._update_thread(channel_id, thread_ts, text)
        else:
            logger.error(f"Response for {request_id} lacks response_url or channel_id")

    def _send_response_url(self, response_url: str, text: str) -> bool:
        """Send a response using a Slack response_url.

        Args:
            response_url: The Slack response URL
            text: The message text to send

        Returns:
            True if successful, False otherwise.
        """
        try:
            payload = {"text": text, "replace_original": False}

            response = requests.post(
                response_url, json=payload, headers={"Content-Type": "application/json"}
            )

            if response.status_code == 200:
                return True
            else:
                logger.error(
                    f"Error posting to response_url: {response.status_code} {response.text}"
                )
                return False

        except Exception as e:
            logger.error(f"Exception sending to response_url: {e}")
            return False

    def _update_thread(self, channel: str, thread_ts: Optional[str], text: str) -> bool:
        """Update a Slack thread using the WebClient.

        Args:
            channel: The channel ID
            thread_ts: The thread timestamp, or None for a new message
            text: The message text

        Returns:
            True if successful, False otherwise.
        """
        try:
            kwargs = {"channel": channel, "text": text}

            # If we have a thread_ts, add it for threading
            if thread_ts:
                kwargs["thread_ts"] = thread_ts

            # Send the message
            self.client.chat_postMessage(**kwargs)  # noqa: F841
            return True

        except SlackApiError as e:
            logger.error(f"Error posting message: {e.response['error']}")
            return False
