/**
 * Main router for the proxy service
 */

const express = require('express');
const apiRoutes = require('./api');
const { getConfig, updateConfig } = require('../config');
const { createLogger } = require('../utils/logger');
const { invalidateCache } = require('../services/redis');
const { recordMetrics } = require('../services/metrics');
const crypto = require('crypto');

// Generate token on startup for cache-bust security
const CACHE_BUST_TOKEN = process.env.CACHE_BUST_TOKEN ||
                        crypto.randomBytes(24).toString('hex');

const router = express.Router();
const logger = createLogger('routes');

// Health check endpoint
router.get('/status', (req, res) => {
  const config = getConfig();

  res.json({
    status: 'healthy',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    features: {
      proxyEnabled: config.featureFlags.proxyEnabled,
      metricsEnabled: config.featureFlags.metricsEnabled,
      cacheEnabled: config.cache.enabled
    }
  });
});

// Configuration endpoint
router.get('/config', (req, res) => {
  const config = getConfig();

  // Don't expose sensitive information
  const safeConfig = {
    transformation: config.transformation,
    cache: {
      enabled: config.cache.enabled,
      ttl: config.cache.ttl
    },
    featureFlags: config.featureFlags
  };

  res.json(safeConfig);
});

// Update configuration
router.post('/config', async (req, res) => {
  try {
    logger.info('Configuration update requested', { newConfig: req.body });

    // Update configuration
    const updatedConfig = await updateConfig(req.body);

    // Return safe version of config
    const safeConfig = {
      transformation: updatedConfig.transformation,
      cache: {
        enabled: updatedConfig.cache.enabled,
        ttl: updatedConfig.cache.ttl
      },
      featureFlags: updatedConfig.featureFlags
    };

    res.json({
      success: true,
      message: 'Configuration updated successfully',
      config: safeConfig
    });
  } catch (error) {
    logger.error('Error updating configuration', { error: error.message });

    res.status(400).json({
      success: false,
      error: 'Configuration update failed',
      message: error.message
    });
  }
});

// Cache-bust endpoint
router.delete('/cache/:key?', async (req, res) => {
  try {
    // Check token for security
    const token = req.query.token;
    if (!token || token !== CACHE_BUST_TOKEN) {
      logger.warn('Unauthorized cache-bust attempt', {
        ip: req.ip,
        providedToken: token ? token.substring(0, 8) + '...' : 'none'
      });

      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Invalid or missing token'
      });
    }

    // Get key pattern from URL parameter or use wildcard
    const keyPattern = req.params.key || '*';

    logger.info(`Cache-bust requested for pattern: ${keyPattern}`);

    // Invalidate cache with the provided pattern
    const removedKeys = await invalidateCache(keyPattern);

    // Record metrics
    recordMetrics('redis_operation', {
      operation: 'invalidate',
      result: 'success'
    });

    return res.json({
      success: true,
      message: `Cache invalidated for pattern: ${keyPattern}`,
      keysRemoved: removedKeys
    });
  } catch (error) {
    logger.error('Error invalidating cache', { error: error.message });

    // Record error metrics
    recordMetrics('error', {
      endpoint: '/cache',
      error: error.message
    });

    return res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to invalidate cache',
      details: error.message
    });
  }
});

// API routes
router.use('/api', apiRoutes);

// Log the cache-bust token on startup (but only part of it for security)
logger.info(`Cache-bust endpoint ready at /cache/:key?token=${CACHE_BUST_TOKEN.substring(0, 8)}...`);

module.exports = router;
