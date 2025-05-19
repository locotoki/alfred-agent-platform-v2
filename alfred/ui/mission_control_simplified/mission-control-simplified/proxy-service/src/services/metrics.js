/**
 * Metrics service for the proxy service
 *
 * Provides Prometheus metrics for monitoring the proxy service performance.
 */

const promClient = require('prom-client');
const { createLogger } = require('../utils/logger');
const { getConfig } = require('../config');

const logger = createLogger('metrics');

// Initialize Prometheus metrics
const transformDurationHistogram = new promClient.Histogram({
  name: 'proxy_transform_duration_ms',
  help: 'Duration of transformation in milliseconds',
  labelNames: ['query', 'category'],
  // Bucket tuning for better visibility around our 400ms SLO target
  buckets: [1, 5, 10, 25, 50, 100, 200, 300, 400, 500, 750, 1000]
});

const relevanceScoreGauge = new promClient.Gauge({
  name: 'proxy_relevance_score',
  help: 'Relevance score for niche transformation',
  labelNames: ['query', 'category']
});

const relevantNicheCountGauge = new promClient.Gauge({
  name: 'proxy_relevant_niche_count',
  help: 'Number of relevant niches returned',
  labelNames: ['query', 'category']
});

const matchTypesCounter = new promClient.Counter({
  name: 'proxy_match_types',
  help: 'Types of matches found during transformation',
  labelNames: ['query', 'category', 'match_type']
});

const cacheHitRatioGauge = new promClient.Gauge({
  name: 'proxy_cache_hit_ratio',
  help: 'Ratio of cache hits to total requests',
});

const apiResponseTimeHistogram = new promClient.Histogram({
  name: 'proxy_api_response_time_ms',
  help: 'Response time of Social Intelligence API in milliseconds',
  labelNames: ['endpoint'],
  // Bucket tuning for better visibility around our 400ms SLO target with additional precision
  buckets: [10, 50, 100, 200, 300, 400, 500, 750, 1000, 1500, 2000, 3000, 5000, 10000]
});

const totalRequestsCounter = new promClient.Counter({
  name: 'proxy_total_requests',
  help: 'Total number of requests processed',
  labelNames: ['endpoint', 'status']
});

// Cache metrics
const redisOpsCounter = new promClient.Counter({
  name: 'proxy_redis_operations',
  help: 'Number of Redis operations',
  labelNames: ['operation', 'result']
});

const memoryCacheGauge = new promClient.Gauge({
  name: 'proxy_memory_cache_size',
  help: 'Number of items in memory cache'
});

const memoryCacheActiveGauge = new promClient.Gauge({
  name: 'proxy_memory_cache_active_items',
  help: 'Number of active items in memory cache'
});

// Error rate gauge
const errorRateGauge = new promClient.Gauge({
  name: 'proxy_error_rate',
  help: 'Rate of errors in last minute'
});

// Latency gauge for p95
const p95LatencyGauge = new promClient.Gauge({
  name: 'proxy_p95_latency',
  help: 'P95 latency in seconds'
});

// Cache hit/miss tracking
let cacheHits = 0;
let cacheMisses = 0;

// Error tracking for error rate calculation
const errorHistory = [];
const ERROR_WINDOW_MS = 60000; // 1 minute window

// Response time tracking for p95 calculation
const responseTimeHistory = [];
const RESPONSE_WINDOW_MS = 60000; // 1 minute window

/**
 * Record metrics from transformation process
 * @param {string} type - Metrics type (transformation, cache_hit, error, etc.)
 * @param {Object} data - Metrics data
 */
function recordMetrics(type, data = {}) {
  const config = getConfig();

  // Skip if metrics are disabled
  if (!config.featureFlags.metricsEnabled) {
    return;
  }

  try {
    const { query = '', category = '' } = data;
    const now = Date.now();

    switch (type) {
      case 'transformation':
        // Record transformation metrics
        if (data.transformationTime) {
          transformDurationHistogram.labels(query, category).observe(data.transformationTime);

          // Add to response time history for p95 calculation
          responseTimeHistory.push({
            time: now,
            duration: data.transformationTime / 1000 // convert to seconds
          });
          // Clean up old entries
          cleanupHistory(responseTimeHistory, now, RESPONSE_WINDOW_MS);

          // Update p95 latency
          updateP95Latency();
        }

        if (data.relevanceScore !== undefined) {
          relevanceScoreGauge.labels(query, category).set(data.relevanceScore);
        }

        if (data.relevantNicheCount !== undefined) {
          relevantNicheCountGauge.labels(query, category).set(data.relevantNicheCount);
        }

        // Record match types
        if (data.matchTypes) {
          Object.entries(data.matchTypes).forEach(([matchType, count]) => {
            matchTypesCounter.labels(query, category, matchType).inc(count);
          });
        }

        break;

      case 'api_request':
        // Record API request metrics
        totalRequestsCounter.labels('/api/youtube/niche-scout', 'success').inc();

        if (data.apiResponseTime) {
          apiResponseTimeHistogram.labels('/api/youtube/niche-scout').observe(data.apiResponseTime);
        }

        // Record cache miss
        cacheMisses++;
        updateCacheHitRatio();

        break;

      case 'cache_hit':
        // Record cache hit metrics
        totalRequestsCounter.labels('/api/youtube/niche-scout', 'success').inc();

        // Record cache hit
        cacheHits++;
        updateCacheHitRatio();

        break;

      case 'redis_operation':
        // Record Redis operation metrics
        if (data.operation && data.result) {
          redisOpsCounter.labels(data.operation, data.result).inc();
        }

        // Update memory cache stats if provided
        if (data.memoryCache) {
          memoryCacheGauge.set(data.memoryCache.size || 0);
          memoryCacheActiveGauge.set(data.memoryCache.activeItems || 0);
        }

        break;

      case 'error':
        // Record error metrics
        totalRequestsCounter.labels(data.endpoint || '/api/youtube/niche-scout', 'error').inc();

        // Add to error history for error rate calculation
        errorHistory.push({
          time: now,
          endpoint: data.endpoint || '/api/youtube/niche-scout'
        });

        // Clean up old entries
        cleanupHistory(errorHistory, now, ERROR_WINDOW_MS);

        // Update error rate
        updateErrorRate();

        break;

      default:
        logger.warn(`Unknown metrics type: ${type}`);
    }
  } catch (error) {
    logger.error('Error recording metrics', { error: error.message });
  }
}

/**
 * Update cache hit ratio gauge
 */
function updateCacheHitRatio() {
  const total = cacheHits + cacheMisses;
  if (total > 0) {
    cacheHitRatioGauge.set(cacheHits / total);
  }
}

/**
 * Update error rate gauge based on error history
 */
function updateErrorRate() {
  const now = Date.now();
  const total = errorHistory.length + responseTimeHistory.length;

  if (total > 0) {
    const errorRate = errorHistory.length / total;
    errorRateGauge.set(errorRate);
  } else {
    errorRateGauge.set(0);
  }
}

/**
 * Update p95 latency gauge based on response time history
 */
function updateP95Latency() {
  if (responseTimeHistory.length === 0) {
    p95LatencyGauge.set(0);
    return;
  }

  // Sort durations ascending
  const durations = responseTimeHistory.map(entry => entry.duration).sort((a, b) => a - b);

  // Calculate p95 index
  const p95Index = Math.floor(durations.length * 0.95);

  // Get p95 value
  const p95Value = durations[Math.min(p95Index, durations.length - 1)];

  // Update gauge
  p95LatencyGauge.set(p95Value);
}

/**
 * Clean up history arrays by removing entries older than window
 * @param {Array} array - Array to clean up
 * @param {number} now - Current timestamp
 * @param {number} windowMs - Window size in milliseconds
 */
function cleanupHistory(array, now, windowMs) {
  const cutoff = now - windowMs;
  let i = 0;

  // Find index of first entry to keep
  while (i < array.length && array[i].time < cutoff) {
    i++;
  }

  // Remove old entries
  if (i > 0) {
    array.splice(0, i);
  }
}

/**
 * Record Redis operation metrics and memory cache stats
 */
function recordRedisMetrics() {
  const { getMemoryCacheStats } = require('./redis');

  try {
    // Get memory cache stats
    const memoryCacheStats = getMemoryCacheStats();

    // Record metrics
    recordMetrics('redis_operation', {
      operation: 'stats',
      result: 'success',
      memoryCache: memoryCacheStats
    });
  } catch (error) {
    logger.error('Error recording Redis metrics', { error: error.message });
  }
}

/**
 * Get metrics registry for Prometheus endpoint
 * @returns {Object} - Prometheus registry
 */
function getMetricsRegistry() {
  // Update memory cache metrics before returning
  recordRedisMetrics();

  return promClient.register;
}

module.exports = {
  recordMetrics,
  getMetricsRegistry
};
