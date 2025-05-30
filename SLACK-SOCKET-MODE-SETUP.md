# Slack Socket Mode Setup

## What is Socket Mode?
Socket Mode allows your Slack app to connect to Slack via WebSocket instead of receiving webhooks. This means:
- ✅ No public URL needed
- ✅ Works behind firewalls
- ✅ Works on localhost
- ✅ No ngrok required

## Setup Instructions

### 1. Get App-Level Token
1. Go to https://api.slack.com/apps
2. Select your app
3. Go to "Basic Information"
4. Scroll to "App-Level Tokens"
5. Click "Generate Token and Scopes"
6. Add scope: `connections:write`
7. Name it: "Socket Mode Token"
8. Copy the token (starts with `xapp-`)

### 2. Enable Socket Mode
1. Go to "Socket Mode" in the left menu
2. Toggle "Enable Socket Mode" to ON
3. Your app will now use WebSocket connections

### 3. Set Environment Variable
Add to your `.env` file:
```bash
SLACK_APP_TOKEN=xapp-1-YOUR-TOKEN-HERE
```

### 4. Restart slack-bot
```bash
docker stop slack-bot && docker rm slack-bot
TAG=socket-mode docker-compose up -d slack-bot
```

### 5. Test
Try `/alfred help` in Slack - it should work without any public URL!

## How It Works
- Bot connects outbound to Slack via WebSocket
- Slack sends events through the WebSocket connection
- No incoming HTTP connections needed
- Perfect for development and behind-firewall deployments

## Verification
Check logs for Socket Mode connection:
```bash
docker logs slack-bot | grep -i socket
```

You should see: "Starting Socket Mode handler..."