/**
 * Niche-Scout Proxy Service
 *
 * This service sits between the Mission Control frontend and the Social Intelligence API,
 * providing transformation, caching, and metrics collection for the Niche-Scout workflow.
 */

const express = require('express');
const cors = require('cors');
const promBundle = require('express-prom-bundle');
const { createLogger } = require('./utils/logger');
const { initializeRedis } = require('./services/redis');
const { loadConfig } = require('./config');
const routes = require('./routes');

// Load environment variables
require('dotenv').config();

// Initialize logger
const logger = createLogger();

// Create Express app
const app = express();
const PORT = process.env.PORT || 3020;

// Prometheus metrics middleware
const metricsMiddleware = promBundle({
  includeMethod: true,
  includePath: true,
  includeStatusCode: true,
  includeUp: true,
  customLabels: { app: 'niche-scout-proxy' },
  promClient: { collectDefaultMetrics: {} }
});

// Middleware
app.use(metricsMiddleware);
app.use(cors());
app.use(express.json());

// Request logging middleware
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.path}`, {
    ip: req.ip,
    userAgent: req.get('User-Agent')
  });
  next();
});

// Routes
app.use('/', routes);

// Global error handler
app.use((err, req, res, next) => {
  logger.error('Unhandled error', { error: err.message, stack: err.stack });
  res.status(500).json({
    error: 'Internal Server Error',
    message: err.message
  });
});

// Start the server
async function start() {
  try {
    // Initialize Redis connection
    await initializeRedis();
    logger.info('Redis connection established');

    // Load configuration
    await loadConfig();
    logger.info('Configuration loaded');

    // Start Express server
    app.listen(PORT, () => {
      logger.info(`
      ======================================================
       Niche-Scout Proxy Service running on port ${PORT}
      ======================================================

      API Endpoints:
      - Health check: http://localhost:${PORT}/status
      - Niche-Scout: http://localhost:${PORT}/api/youtube/niche-scout (POST)
      - Metrics: http://localhost:${PORT}/metrics
      - Config: http://localhost:${PORT}/config (POST)

      ======================================================
      `);
    });
  } catch (error) {
    logger.error('Failed to start server', { error: error.message, stack: error.stack });
    process.exit(1);
  }
}

// Handle unhandled rejections
process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled Rejection', { reason, promise });
});

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  logger.error('Uncaught Exception', { error: error.message, stack: error.stack });
  process.exit(1);
});

// Start the application
start();
