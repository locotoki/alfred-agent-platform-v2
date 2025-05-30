# Slack "dispatch_failed" Error - Diagnosis

## What "dispatch_failed" Means
This error occurs when Slack cannot reach the configured webhook URL for your slash command.

## Current Status
- ✅ slack-bot is running and healthy on port 3011
- ✅ Health endpoint working: http://localhost:3011/health
- ✅ Redis connection working with authentication
- ✅ Slack events endpoint exists at /slack/events
- ❌ No incoming requests from Slack reaching the bot

## Root Cause
The "dispatch_failed" error indicates that Slack cannot reach your server. This is a network/configuration issue, not a code issue.

## Required Slack App Configuration

### 1. Check Slash Commands Configuration
In your Slack app settings (api.slack.com):
- Go to "Slash Commands"
- Find the `/alfred` command
- The Request URL should be: `https://YOUR_PUBLIC_DOMAIN:3011/slack/events`

### 2. Required URLs
- **Slash Commands**: `https://YOUR_PUBLIC_DOMAIN:3011/slack/events`
- **Event Subscriptions**: `https://YOUR_PUBLIC_DOMAIN:3011/slack/events`
- **Interactivity & Shortcuts**: `https://YOUR_PUBLIC_DOMAIN:3011/slack/events`

### 3. Common Issues
1. **Using localhost**: Slack cannot reach `http://localhost:3011`
2. **No public URL**: You need a publicly accessible URL
3. **Firewall blocking**: Port 3011 must be open
4. **HTTPS required**: Slack requires HTTPS for production

## Solutions

### Option 1: Use ngrok (for testing)
```bash
ngrok http 3011
# Use the HTTPS URL provided by ngrok in Slack app settings
```

### Option 2: Use a reverse proxy
Configure nginx/apache to proxy requests to localhost:3011

### Option 3: Deploy to a public server
Ensure the server has:
- Public IP/domain
- Port 3011 accessible
- HTTPS configured

## Verification Steps
1. Check Slack app configuration for correct URLs
2. Ensure the URL is publicly accessible
3. Test with: `curl https://YOUR_PUBLIC_DOMAIN:3011/health`
4. Check firewall rules for port 3011
5. Monitor slack-bot logs when testing commands

## Current Docker Configuration
```yaml
slack-bot:
  ports:
    - 3011:8000  # Exposed on port 3011
```

The bot is working correctly locally. The issue is that Slack cannot reach it from the internet.

---
*Diagnosis Date: May 30, 2025*