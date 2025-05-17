const { App } = require('@slack/bolt');
const Redis = require('ioredis');
const dotenv = require('dotenv');
const pino = require('pino');
const express = require('express');

// Load environment variables
dotenv.config();

// Initialize logger
const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  transport: {
    target: 'pino-pretty',
    options: {
      colorize: true
    }
  }
});

// Initialize Redis client
const redis = new Redis({
  host: process.env.REDIS_HOST || 'localhost',
  port: parseInt(process.env.REDIS_PORT || '6379'),
  password: process.env.REDIS_PASSWORD || '',
  db: parseInt(process.env.REDIS_DB || '0')
});

redis.on('connect', () => {
  logger.info('Connected to Redis');
});

redis.on('error', (err) => {
  logger.error({ err }, 'Redis error');
});

// Initialize Express app for health checks
const expressApp = express();

// Health check endpoint
expressApp.get('/health', (req, res) => {
  if (redis.status === 'ready') {
    res.status(200).json({ status: 'ok', redis: 'connected' });
  } else {
    res.status(503).json({ status: 'error', redis: redis.status });
  }
});

// Initialize Slack app
const app = new App({
  token: process.env.SLACK_BOT_TOKEN,
  signingSecret: process.env.SLACK_SIGNING_SECRET,
  socketMode: true,
  appToken: process.env.SLACK_APP_TOKEN,
  customRoutes: [
    {
      path: '/health',
      method: ['GET'],
      handler: (req, res) => {
        if (redis.status === 'ready') {
          res.writeHead(200);
          res.end(JSON.stringify({ status: 'ok', redis: 'connected' }));
        } else {
          res.writeHead(503);
          res.end(JSON.stringify({ status: 'error', redis: redis.status }));
        }
      },
    },
  ],
});

// Register slash command handlers
app.command('/ping', async ({ command, ack, respond }) => {
  // Acknowledge command request
  await ack();

  const commandData = {
    command: 'ping',
    user_id: command.user_id,
    channel_id: command.channel_id,
    team_id: command.team_id,
    text: command.text,
    timestamp: new Date().toISOString()
  };

  try {
    // Publish command to Redis channel
    await redis.publish('slack:commands', JSON.stringify(commandData));
    logger.info({ command: 'ping' }, 'Command published to Redis');
    
    // Respond to user
    await respond({
      text: '🏓 Pong! Command received and forwarded to mission control.'
    });
  } catch (error) {
    logger.error({ err: error }, 'Failed to process ping command');
    
    await respond({
      text: '❌ Error processing your request. Please try again later.'
    });
  }
});

// Error handler
app.error((error) => {
  logger.error({ err: error }, 'An error occurred in the Slack app');
});

// Start the app
(async () => {
  const port = process.env.PORT || 3000;
  
  // Start both Express (for health checks) and Bolt app
  expressApp.listen(port, () => {
    logger.info(`Express server for health checks is running on port ${port}`);
  });
  
  await app.start();
  logger.info(`⚡️ Slack MCP Gateway is running with Socket Mode`);
})();