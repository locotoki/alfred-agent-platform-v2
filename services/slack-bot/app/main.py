import logging
import os

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("main")

# Use Socket Mode if app token is available
if os.environ.get("SLACK_APP_TOKEN"):
    logger.info("SLACK_APP_TOKEN detected, loading Socket Mode bot")

else:
    logger.info("No SLACK_APP_TOKEN, loading regular bot")
