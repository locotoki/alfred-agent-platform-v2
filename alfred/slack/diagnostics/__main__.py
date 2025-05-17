"""Main entry point for diagnostics bot."""

import asyncio
import os
import structlog
from slack_bolt.adapter.socket_mode.async_handler import AsyncSocketModeHandler
from slack_bolt.app.async_app import AsyncApp

from alfred.slack.diagnostics.bot import DiagnosticsBot

logger = structlog.get_logger()


async def main() -> None:
    """Run the diagnostics bot."""
    # Initialize Slack app
    app = AsyncApp(
        token=os.environ.get("SLACK_BOT_TOKEN"),
        signing_secret=os.environ.get("SLACK_SIGNING_SECRET"),
    )
    
    # Initialize diagnostics bot
    bot = DiagnosticsBot(
        slack_client=app.client,
        prometheus_url=os.environ.get("PROMETHEUS_URL", "http://prometheus:9090"),
        enabled=True,
    )
    
    # Register slash command handler
    @app.command("/diag")
    async def handle_diag_command(ack, command, logger):
        await ack()
        try:
            await bot.handle_command(
                command="/diag",
                channel=command["channel_id"],
                user=command["user_id"],
                text=command["text"],
            )
        except Exception as e:
            logger.error(f"Error handling command: {e}")
    
    # Socket mode setup if enabled
    if os.environ.get("SOCKET_MODE_ENABLED", "true").lower() == "true":
        handler = AsyncSocketModeHandler(
            app=app,
            app_token=os.environ.get("SLACK_APP_TOKEN"),
        )
        logger.info("Starting bot in socket mode...")
        await handler.start_async()
    else:
        # Web API mode
        logger.info("Starting bot in web API mode...")
        await app.start(port=8080)


if __name__ == "__main__":
    asyncio.run(main())