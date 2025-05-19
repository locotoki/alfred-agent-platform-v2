const { App } = require('@slack/bolt');
const { createClient } = require('redis');
const express = require('express');
const winston = require('winston');
const { randomUUID } = require('crypto');

// Initialize logger
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console()
  ]
});

// Configuration
const config = {
  slack: {
    appToken: process.env.SLACK_APP_TOKEN,
    botToken: process.env.SLACK_BOT_TOKEN,
  },
  redis: {
    url: process.env.REDIS_URL || 'redis://redis:6379',
    requestStream: 'mcp.requests',
    responseStream: 'mcp.responses',
    consumerGroup: 'slack-gateway',
    consumerName: `slack-gateway-${process.env.HOSTNAME || 'local'}`
  },
  server: {
    port: process.env.PORT || 3000
  }
};

// Validate required environment variables
if (!config.slack.appToken || !config.slack.botToken) {
  logger.error('Missing required environment variables: SLACK_APP_TOKEN and/or SLACK_BOT_TOKEN');
  process.exit(1);
}

// Initialize Slack app
const slack = new App({
  token: config.slack.botToken,
  appToken: config.slack.appToken,
  socketMode: true,
  logLevel: process.env.LOG_LEVEL || 'info'
});

// Initialize Redis client
const redis = createClient({
  url: config.redis.url,
  socket: {
    reconnectStrategy: (retries) => Math.min(retries * 50, 500)
  }
});

// Redis subscriber for responses
const redisSubscriber = redis.duplicate();

// Health check server
const healthApp = express();
let isHealthy = true;

healthApp.get('/health', (req, res) => {
  if (isHealthy && redis.isReady && slack.receiver.client?.isActive()) {
    res.status(200).json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      services: {
        slack: 'connected',
        redis: 'connected'
      }
    });
  } else {
    res.status(503).json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      services: {
        slack: slack.receiver.client?.isActive() ? 'connected' : 'disconnected',
        redis: redis.isReady ? 'connected' : 'disconnected'
      }
    });
  }
});

// Command handler for /alfred
slack.command('/alfred', async ({ command, ack, say }) => {
  try {
    // Immediately acknowledge the command
    await ack();

    const requestId = randomUUID();
    const timestamp = Date.now();

    // Prepare the request for Redis
    const request = {
      id: requestId,
      type: 'slack_command',
      command: command.command,
      text: command.text || '',
      timestamp: timestamp.toString(),
      user_id: command.user_id,
      user_name: command.user_name,
      channel_id: command.channel_id,
      team_id: command.team_id,
      response_url: command.response_url
    };

    logger.info('Received Slack command', { requestId, command: command.text });

    // Save response metadata for later
    await redis.hSet(`request:${requestId}`, {
      channel_id: command.channel_id,
      user_id: command.user_id,
      timestamp: timestamp.toString()
    });

    // Set expiry for metadata (1 hour)
    await redis.expire(`request:${requestId}`, 3600);

    // Publish to Redis stream
    await redis.xAdd(config.redis.requestStream, '*', request);

    logger.info('Published command to Redis', { requestId, stream: config.redis.requestStream });

    // Send initial acknowledgment to user
    await say({
      text: `Processing your request "${command.text}"...`,
      thread_ts: timestamp.toString()
    });

  } catch (error) {
    logger.error('Error processing command', { error: error.message, stack: error.stack });
    try {
      await say('Sorry, an error occurred processing your command. Please try again.');
    } catch (sayError) {
      logger.error('Error sending error message to Slack', { error: sayError.message });
    }
  }
});

// Redis response handler
async function handleRedisResponses() {
  try {
    // Create consumer group if it doesn't exist
    try {
      await redisSubscriber.xGroupCreate(
        config.redis.responseStream,
        config.redis.consumerGroup,
        '0',
        { MKSTREAM: true }
      );
    } catch (error) {
      if (!error.message.includes('BUSYGROUP')) {
        throw error;
      }
    }

    logger.info('Starting Redis response consumer', {
      stream: config.redis.responseStream,
      group: config.redis.consumerGroup,
      consumer: config.redis.consumerName
    });

    while (isHealthy) {
      try {
        // Read from stream
        const messages = await redisSubscriber.xReadGroup(
          config.redis.consumerGroup,
          config.redis.consumerName,
          [{ key: config.redis.responseStream, id: '>' }],
          {
            BLOCK: 5000,
            COUNT: 10
          }
        );

        if (messages && messages.length > 0) {
          for (const stream of messages) {
            for (const message of stream.messages) {
              await processResponse(message);
            }
          }
        }
      } catch (error) {
        logger.error('Error reading from Redis stream', { error: error.message });
        await new Promise(resolve => setTimeout(resolve, 1000));
      }
    }
  } catch (error) {
    logger.error('Fatal error in Redis response handler', { error: error.message });
    isHealthy = false;
  }
}

// Process individual response
async function processResponse(message) {
  try {
    const { id: messageId, message: data } = message;
    const requestId = data.request_id;

    logger.info('Processing response', { messageId, requestId });

    // Get original request metadata
    const metadata = await redis.hGetAll(`request:${requestId}`);

    if (!metadata.channel_id) {
      logger.warn('No metadata found for request', { requestId });
      return;
    }

    // Send response to Slack
    await slack.client.chat.postMessage({
      channel: metadata.channel_id,
      text: data.text || 'Response received',
      thread_ts: metadata.timestamp,
      blocks: data.blocks ? JSON.parse(data.blocks) : undefined
    });

    // Acknowledge message
    await redisSubscriber.xAck(
      config.redis.responseStream,
      config.redis.consumerGroup,
      messageId
    );

    logger.info('Response sent to Slack', { requestId, channel: metadata.channel_id });

  } catch (error) {
    logger.error('Error processing response', { error: error.message, messageId: message.id });
  }
}

// Graceful shutdown
async function shutdown(signal) {
  logger.info(`Received ${signal}, shutting down gracefully`);
  isHealthy = false;

  try {
    // Stop accepting new connections
    healthServer.close();

    // Disconnect from Redis
    await redis.quit();
    await redisSubscriber.quit();

    // Stop Slack app
    await slack.stop();

    logger.info('Shutdown complete');
    process.exit(0);
  } catch (error) {
    logger.error('Error during shutdown', { error: error.message });
    process.exit(1);
  }
}

// Start the service
async function start() {
  try {
    // Connect to Redis
    await redis.connect();
    await redisSubscriber.connect();
    logger.info('Connected to Redis');

    // Start Slack app
    await slack.start();
    logger.info('Connected to Slack');

    // Start health check server
    const healthServer = healthApp.listen(config.server.port, () => {
      logger.info(`Health check server listening on port ${config.server.port}`);
    });

    // Start Redis response handler
    handleRedisResponses();

    // Register shutdown handlers
    process.on('SIGTERM', () => shutdown('SIGTERM'));
    process.on('SIGINT', () => shutdown('SIGINT'));

    logger.info('Slack MCP Gateway started successfully');

  } catch (error) {
    logger.error('Failed to start service', { error: error.message });
    process.exit(1);
  }
}

// Start the application
start();
