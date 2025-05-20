# Environment File Management

This document explains the streamlined approach to environment file management in the Alfred Agent Platform v2.

## Environment Files Structure

We use a simplified approach with three main environment files:

1. **`.env`** - CI-managed environment file with default values. **Do not modify this file directly**.

2. **`.env.example`** - Template file with all possible variables and documentation.

3. **`.env.local`** - Your local development overrides (git-ignored). This is where you should put your custom settings.

## Quick Setup

We provide a setup script that creates a proper local development environment:

```bash
# Run the setup script
./setup-dev-env.sh

# Start the platform using the wrapper script
./docker-compose-env.sh -f docker-compose-clean.yml up
```

## Manual Setup

If you prefer to set up manually:

1. Copy the example file to create your local overrides:
   ```bash
   cp .env.example .env.local
   ```

2. Edit `.env.local` with your custom settings:
   ```bash
   nano .env.local
   ```

3. Use the wrapper script to start docker-compose with both environment files:
   ```bash
   ./docker-compose-env.sh -f docker-compose-clean.yml up
   ```

## Essential Variables

At minimum, you should configure the following in your `.env.local`:

- `ALFRED_ENVIRONMENT=development`
- `ALFRED_DEBUG=true`
- `DB_PASSWORD=your-password`
- `ALFRED_DATABASE_URL=postgresql://postgres:your-password@db-postgres:5432/postgres`
- `ALFRED_OPENAI_API_KEY=<your_api_key>` (for LLM services)

For Slack integration:
- `SLACK_BOT_TOKEN=xoxb-your-token`
- `SLACK_APP_TOKEN=xapp-your-token`
- `SLACK_SIGNING_SECRET=your-secret`

## Staging and Production

For other environments:
- Create `.env.staging` or `.env.production` files with appropriate settings
- Use the wrapper script with the appropriate file:
  ```bash
  ./docker-compose-env.sh --env-file .env --env-file .env.staging -f docker-compose-clean.yml up
  ```

## Troubleshooting

If your settings aren't being applied:
1. Ensure your `.env.local` file exists and contains the correct variables
2. Try using the wrapper script: `./docker-compose-env.sh` instead of direct `docker-compose` commands
3. Check that Docker is running: `sudo service docker start`
