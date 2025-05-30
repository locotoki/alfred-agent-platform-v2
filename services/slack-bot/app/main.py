import os

# Use Socket Mode if app token is available
if os.environ.get("SLACK_APP_TOKEN"):
    from bot_socket_mode import app
else:
    from bot import app
