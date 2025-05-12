"""
Slack interface for Alfred.
This module implements the Slack-specific functionality that integrates with the core API.
"""

import os
import re
from typing import Optional, Dict, Any

import structlog
from fastapi import FastAPI, Request
from slack_bolt import App
from slack_bolt.adapter.fastapi import SlackRequestHandler

from .core import AlfredCore

logger = structlog.get_logger(__name__)

class SlackInterface:
    """
    Slack interface implementation for Alfred.
    This class handles Slack-specific events and commands, delegating the business logic to the core.
    """
    
    def __init__(self, core: AlfredCore):
        """
        Initialize the Slack interface with the provided core.
        
        Args:
            core: The Alfred core instance to use for processing
        """
        self.core = core
        
        # Initialize Slack app with environment variables
        self.slack_app = App(
            token=os.environ.get("SLACK_BOT_TOKEN"),
            signing_secret=os.environ.get("SLACK_SIGNING_SECRET")
        )
        
        # Register event handlers
        self._register_handlers()
        
        logger.info("slack_interface_initialized")
    
    def _register_handlers(self):
        """Register all the Slack event and command handlers."""
        # Slash command handler
        @self.slack_app.command("/alfred")
        async def handle_alfred_command(ack, body, client):
            """Handle /alfred slash command."""
            await ack()
            
            try:
                command_text = body.get("text", "").strip()
                user_id = body["user_id"]
                channel_id = body["channel_id"]
                thread_ts = body.get("thread_ts")
                
                # Process with core
                response = await self.core.process_message(command_text, user_id, channel_id, thread_ts)
                
                # Send response back to Slack
                await client.chat_postMessage(
                    channel=channel_id,
                    thread_ts=thread_ts,
                    text=response
                )
            
            except Exception as e:
                logger.error("command_handling_failed", error=str(e))
                await client.chat_postMessage(
                    channel=channel_id,
                    thread_ts=thread_ts if 'thread_ts' in locals() else None,
                    text="Sorry, something went wrong. Please try again later."
                )
        
        # Direct message handler
        @self.slack_app.event("message")
        async def handle_message_events(body, logger, client):
            """Handle direct messages to the bot."""
            # Filter out bot messages to prevent loops
            if body.get("event", {}).get("bot_id"):
                return
            
            # Extract message details
            event = body["event"]
            user_id = event.get("user")
            channel_id = event.get("channel")
            text = event.get("text", "").strip()
            thread_ts = event.get("thread_ts")
            
            # Check if this is a DM channel
            is_dm = channel_id.startswith("D")
            
            # Process the message if it's a DM
            if is_dm:
                await self._process_slack_message(client, channel_id, user_id, text, thread_ts, is_dm)
        
        # Mention handler
        @self.slack_app.event("app_mention")
        async def handle_mentions(body, logger, client):
            """Handle mentions of the bot in channels."""
            event = body["event"]
            user_id = event.get("user")
            channel_id = event.get("channel")
            text = event.get("text", "").strip()
            thread_ts = event.get("thread_ts")
            
            # Remove the bot mention from the text
            # Format is typically <@BOT_USER_ID> command args
            text = re.sub(r'<@[A-Z0-9]+>', '', text).strip()
            
            # Process the message
            await self._process_slack_message(client, channel_id, user_id, text, thread_ts, False)
    
    async def _process_slack_message(self, client, channel_id, user_id, text, thread_ts=None, is_dm=False):
        """
        Process a message from Slack.
        
        Args:
            client: The Slack client
            channel_id: The channel ID
            user_id: The user ID
            text: The message text
            thread_ts: The thread timestamp (if in a thread)
            is_dm: Whether this is a direct message
        """
        try:
            # Direct messages don't need a prefix
            if is_dm:
                # Process with core
                response = await self.core.process_message(text, user_id, channel_id, thread_ts)
                
                # Send response back to Slack
                await client.chat_postMessage(
                    channel=channel_id,
                    thread_ts=thread_ts,
                    text=response
                )
            else:
                # In channels, require explicit command format
                if text.startswith("alfred") or (is_dm and text.startswith("alfred")):
                    # Strip prefix
                    stripped_text = text.replace("alfred", "").strip()
                    
                    # Process with core
                    response = await self.core.process_message(stripped_text, user_id, channel_id, thread_ts)
                    
                    # Send response back to Slack
                    await client.chat_postMessage(
                        channel=channel_id,
                        thread_ts=thread_ts,
                        text=response
                    )
        
        except Exception as e:
            logger.error("message_processing_failed", error=str(e))
            await client.chat_postMessage(
                channel=channel_id,
                thread_ts=thread_ts,
                text="Sorry, something went wrong. Please try again later."
            )

def create_slack_app(app: FastAPI, core: AlfredCore):
    """
    Add Slack interface to a FastAPI application.
    
    Args:
        app: The FastAPI application to add routes to
        core: The Alfred core instance to use
    """
    # Only initialize Slack if credentials are available
    if not os.environ.get("SLACK_BOT_TOKEN") or not os.environ.get("SLACK_SIGNING_SECRET"):
        logger.warning("slack_credentials_missing", message="Slack interface disabled due to missing credentials")
        return
    
    # Initialize Slack interface
    slack_interface = SlackInterface(core)
    
    # Create request handler
    slack_handler = SlackRequestHandler(slack_interface.slack_app)
    
    # Add Slack endpoints to FastAPI app
    @app.post("/slack/events")
    async def slack_events(request: Request):
        """Handle Slack events."""
        return await slack_handler.handle(request)
    
    @app.post("/slack/install")
    async def slack_install():
        """Handle Slack app installation."""
        return {"status": "not_implemented", "message": "Installation endpoint not yet implemented"}
    
    logger.info("slack_interface_routes_added")