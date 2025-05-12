# Alfred Slack Bot Setup Guide

This guide provides step-by-step instructions for setting up the Alfred Slack Bot for the Alfred Agent Platform v2. The bot provides a conversational interface to the platform via Slack, enabling users to interact with Alfred's capabilities directly from their Slack workspace.

## Requirements

- Slack workspace with admin privileges
- ngrok account (free or paid)
- Alfred Agent Platform v2 running locally

## 1. Create a Slack App

1. Go to [Slack API Apps](https://api.slack.com/apps) and sign in with your Slack credentials.
2. Click "Create New App" and select "From scratch."
3. Enter "Alfred Bot" for the app name and select your workspace.
4. Click "Create App."

## 2. Configure Basic Information

1. In the left sidebar, click "Basic Information."
2. Under "Display Information," add:
   - App name: Alfred Bot
   - Short description: AI assistant for the Alfred Agent Platform
   - App icon: [Optional] Upload an icon
   - Background color: #4a154b (Slack purple) or your preferred color
3. Scroll down to "App Credentials" and make note of your "Signing Secret" - you'll need it later.

## 3. Configure Bot Features

1. In the left sidebar, click "OAuth & Permissions."
2. Scroll down to "Scopes" and add the following Bot Token Scopes:
   - `app_mentions:read` - View messages that mention your app
   - `chat:write` - Send messages as the app
   - `chat:write.customize` - Send messages with customizations
   - `commands` - Add slash commands
   - `im:history` - View messages in direct messages
   - `im:read` - View basic information about direct messages
   - `im:write` - Send messages in direct messages
   
3. Scroll back to the top and click "Install to Workspace."
4. Review the permissions and click "Allow."
5. After installation, make note of the "Bot User OAuth Token" (starts with `xoxb-`) - you'll need it later.

## 4. Configure Slash Commands

1. In the left sidebar, click "Slash Commands."
2. Click "Create New Command."
3. Fill in the command details:
   - Command: `/alfred`
   - Request URL: `https://your-ngrok-url.ngrok.io/slack/events` (we'll set this up later)
   - Short Description: Interact with Alfred Bot
   - Usage Hint: `help, ping, trend <topic>`
4. Click "Save."

## 5. Configure Event Subscriptions

1. In the left sidebar, click "Event Subscriptions."
2. Toggle "Enable Events" to On.
3. For the Request URL, enter: `https://your-ngrok-url.ngrok.io/slack/events` (we'll update this later)
4. Scroll down to "Subscribe to bot events" and click "Add Bot User Event."
5. Add the following events:
   - `app_mention` - Listen for mentions of your bot
   - `message.im` - Listen for direct messages to your bot
6. Click "Save Changes" at the bottom of the page.

## 6. Set Up Local Environment

1. Clone the Alfred Agent Platform v2 repository (if not already done).
2. Navigate to the repository directory.
3. Create a `.env.slackbot` file in the `services/alfred-bot` directory:

```bash
# Slack Bot Configuration
SLACK_BOT_TOKEN=xoxb-your-token-here  # Replace with your Bot User OAuth Token
SLACK_SIGNING_SECRET=your-signing-secret-here  # Replace with your Signing Secret
SLACK_APP_TOKEN=xapp-your-app-level-token-here  # Optional for socket mode

# Redis Configuration
REDIS_URL=redis://redis:6379

# Supabase Configuration
DATABASE_URL=postgresql://postgres:your-super-secret-password@supabase-db:5432/postgres
SUPABASE_URL=http://supabase-rest:3000
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here

# Google Cloud Configuration
GCP_PROJECT_ID=alfred-agent-platform
PUBSUB_EMULATOR_HOST=pubsub-emulator:8085
```

Make sure to replace the placeholder values with your actual Slack API credentials.

## 7. Start the Platform Services

Before starting the Slack bot, make sure the Alfred Agent Platform services are running:

```bash
./start-production.sh --core --rag
```

This will start the core infrastructure services and the RAG Gateway, which the Slack bot depends on.

## 8. Start the Slack Bot with ngrok

Now you can start the Slack bot with ngrok for local development:

```bash
cd services/alfred-bot
./start-slackbot-dev.sh
```

This script will:
1. Start ngrok to create a public tunnel to your local server
2. Display the ngrok URL that you'll need for the Slack API configuration
3. Start the Slack bot FastAPI application

## 9. Update Slack App Configuration

Once ngrok is running, you'll see a URL like `https://1a2b3c4d.ngrok.io`. Use this URL to update your Slack App configuration:

1. Return to your [Slack API Apps](https://api.slack.com/apps) page.
2. Select your Alfred Bot app.
3. Go to "Event Subscriptions" and update the Request URL with your ngrok URL + `/slack/events`.
4. Go to "Slash Commands" and update the `/alfred` command URL with the same URL.
5. Click "Save Changes" on each page.

## 10. Test the Bot

Now you can test the Alfred Slack bot:

1. **Testing Slash Commands**:
   - In your Slack workspace, type `/alfred help`
   - You should receive a rich help message
   - Try `/alfred ping` to test the bot's responsiveness
   - Try `/alfred trend artificial intelligence` to test trend analysis

2. **Testing Direct Messages**:
   - Open a direct message with the Alfred bot
   - Send a message like "help" or "ping"
   - The bot should respond appropriately

3. **Testing Mentions**:
   - In a channel where the bot is present, mention it with `@Alfred help`
   - The bot should respond with the help message

## 11. Troubleshooting

If you encounter issues, use the diagnostic script:

```bash
./services/alfred-bot/check-slackbot.sh
```

This will check:
- If the Slack bot is running
- If ngrok is running
- If environment variables are set correctly
- Redis connection (if available)
- Slack events endpoint

### Common Issues

1. **Bot not responding to slash commands**:
   - Verify the Request URL is correct in the Slack App configuration
   - Check the logs for any errors: `docker logs alfred-agent-platform-v2-alfred-bot-1`
   - Ensure the bot token has the correct scopes

2. **ngrok URL not working**:
   - Restart ngrok: `ngrok http 8011`
   - Update the Request URL in the Slack App configuration

3. **401 Unauthorized errors**:
   - Check that your Bot User OAuth Token is correct
   - Verify that the bot has been added to the channel

4. **Redis connection errors**:
   - Ensure Redis is running: `docker ps | grep redis`
   - Check the Redis URL in your .env.slackbot file

## 12. Running in Docker

For a more production-like setup, you can run the Slack bot in Docker:

```bash
docker-compose -f docker-compose.combined-fixed.yml up -d alfred-bot
```

For external access, you'll need to set up ngrok separately to tunnel to port 8011:

```bash
ngrok http 8011
```

Then update the Request URL in your Slack App configuration with the new ngrok URL.

## Additional Resources

- [Slack API Documentation](https://api.slack.com/docs)
- [Slack Bolt Python Documentation](https://slack.dev/bolt-python/concepts)
- [ngrok Documentation](https://ngrok.com/docs)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Slack Block Kit Builder](https://app.slack.com/block-kit-builder)