# Slack Tunnel Setup Guide

## The Problem
Slack is showing "dispatch_failed" because it cannot reach your local development server at localhost:3011.

## Quick Solution: Use ngrok

### 1. Install ngrok
```bash
# Download ngrok
wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
tar xvzf ngrok-v3-stable-linux-amd64.tgz
sudo mv ngrok /usr/local/bin/

# Or using snap
sudo snap install ngrok
```

### 2. Start ngrok tunnel
```bash
ngrok http 3011
```

This will show something like:
```
Forwarding  https://abc123.ngrok.io -> http://localhost:3011
```

### 3. Update Slack App Configuration
1. Go to https://api.slack.com/apps
2. Select your app
3. Go to "Slash Commands"
4. Edit the `/alfred` command
5. Update Request URL to: `https://abc123.ngrok.io/slack/events`
6. Save changes

### 4. Test the command
Try `/alfred help` in Slack

## Alternative: SSH Tunnel (if you have a public server)
```bash
# From your local machine
ssh -R 3011:localhost:3011 user@your-public-server.com

# Then update Slack to use https://your-public-server.com:3011/slack/events
```

## Verification
1. Check ngrok web interface: http://localhost:4040
2. Monitor slack-bot logs:
   ```bash
   docker logs -f slack-bot
   ```
3. You should see incoming POST requests when using /alfred

## Important Notes
- ngrok URLs change each time you restart (unless you have a paid account)
- Always use the HTTPS URL from ngrok in Slack settings
- The free ngrok tier has request limits

## Current Status
Your slack-bot is running correctly on port 3011. It just needs to be accessible from the internet for Slack to reach it.