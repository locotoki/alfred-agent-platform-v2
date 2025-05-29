# Slack Token Setup Guide

## 🔐 Secure Token Configuration for slack_mcp_gateway

### Option 1: Using .env file (Development)

1. **Edit the .env file** (already exists in your project):
   ```bash
   # Edit the .env file
   nano .env
   # or
   vim .env
   ```

2. **Add your Slack tokens**:
   ```env
   # Slack MCP Gateway tokens
   SLACK_API_TOKEN=xoxb-your-bot-token-here
   SLACK_BOT_TOKEN=xoxb-your-bot-token-here
   SLACK_APP_TOKEN=xapp-your-app-token-here

   # These might also be needed:
   ALFRED_SLACK_BOT_TOKEN=xoxb-your-bot-token-here
   ALFRED_SLACK_SIGNING_SECRET=your-signing-secret-here
   ALFRED_SLACK_APP_TOKEN=xapp-your-app-token-here
   ```

3. **Restart the service**:
   ```bash
   docker compose --profile core --profile bizdev up -d slack_mcp_gateway
   ```

### Option 2: Using Docker Secrets (More Secure)

1. **Create secret files**:
   ```bash
   # Create a secrets directory
   mkdir -p secrets

   # Create secret files (replace with your actual tokens)
   echo "xoxb-your-bot-token-here" > secrets/slack_bot_token
   echo "xoxb-your-api-token-here" > secrets/slack_api_token

   # Set proper permissions
   chmod 600 secrets/*
   ```

2. **Create docker-compose.secrets.yml**:
   ```yaml
   services:
     slack_mcp_gateway:
       environment:
         - SLACK_BOT_TOKEN_FILE=/run/secrets/slack_bot_token
         - SLACK_API_TOKEN_FILE=/run/secrets/slack_api_token
       secrets:
         - slack_bot_token
         - slack_api_token

   secrets:
     slack_bot_token:
       file: ./secrets/slack_bot_token
     slack_api_token:
       file: ./secrets/slack_api_token
   ```

3. **Start with secrets**:
   ```bash
   docker compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.secrets.yml up -d slack_mcp_gateway
   ```

### Option 3: Environment Variables (Quick Test)

For a quick test, you can pass tokens directly (less secure):

```bash
# Set environment variables
export SLACK_API_TOKEN="xoxb-your-api-token"
export SLACK_BOT_TOKEN="xoxb-your-bot-token"

# Start the service
docker compose --profile core --profile bizdev up -d slack_mcp_gateway
```

### Option 4: Using a .env.local file (Git-ignored)

1. **Create .env.local**:
   ```bash
   cp .env .env.local
   ```

2. **Add to .gitignore**:
   ```bash
   echo ".env.local" >> .gitignore
   ```

3. **Edit .env.local with your tokens**

4. **Use the local env file**:
   ```bash
   docker compose --env-file .env.local --profile core --profile bizdev up -d slack_mcp_gateway
   ```

## 🔍 Getting Slack Tokens

1. Go to https://api.slack.com/apps
2. Create a new app or select existing one
3. Navigate to "OAuth & Permissions"
4. Copy the Bot User OAuth Token (starts with `xoxb-`)
5. For App Token: Go to "Basic Information" > "App-Level Tokens"

## 🛡️ Security Best Practices

- Never commit tokens to Git
- Use `.gitignore` for any files containing secrets
- Rotate tokens regularly
- Use read-only permissions where possible
- Consider using a secrets management system for production

## 📝 Required Scopes

Ensure your Slack app has these OAuth scopes:
- `chat:write`
- `channels:read`
- `channels:history`
- `users:read`
- `app_mentions:read`
- `im:history`
- `im:read`
- `im:write`
