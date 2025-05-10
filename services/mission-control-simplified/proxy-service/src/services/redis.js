/**
 * Redis service for the proxy service
 * 
 * Manages Redis connection and provides utilities for working with Redis.
 */

const Redis = require('ioredis');
const { createLogger } = require('../utils/logger');

const logger = createLogger('redis');

// Redis client instance
let redisClient = null;

// In-memory cache for fallback when Redis is unavailable
const memoryCache = new Map();
const memoryCacheExpiry = new Map();

// Five-minute TTL for memory cache (in milliseconds)
const MEMORY_CACHE_TTL = 5 * 60 * 1000;

/**
 * Initialize Redis connection
 * @returns {Promise<Redis>} - Redis client instance
 */
async function initializeRedis() {
  if (redisClient) {
    return redisClient;
  }

  try {
    const host = process.env.REDIS_HOST || 'localhost';
    const port = parseInt(process.env.REDIS_PORT || '6379', 10);
    const password = process.env.REDIS_PASSWORD || undefined;
    const db = parseInt(process.env.REDIS_DB || '0', 10);

    logger.info(`Connecting to Redis at ${host}:${port}/${db}`);

    redisClient = new Redis({
      host,
      port,
      password,
      db,
      retryStrategy: (times) => {
        const delay = Math.min(times * 50, 2000);
        logger.info(`Retrying Redis connection in ${delay}ms`);
        return delay;
      }
    });

    // Handle connection events
    redisClient.on('connect', () => {
      logger.info('Redis client connected');
    });

    redisClient.on('error', (err) => {
      logger.error('Redis connection error', { error: err.message });
    });

    redisClient.on('close', () => {
      logger.warn('Redis connection closed');
    });

    // Test connection
    await redisClient.ping();
    
    return redisClient;
  } catch (error) {
    logger.error('Failed to initialize Redis', { error: error.message });
    
    // Create a mock Redis client for graceful fallback if Redis is unavailable
    if (!redisClient) {
      logger.warn('Using in-memory Redis mock for graceful fallback');
      redisClient = createRedisMock();
    }
    
    return redisClient;
  }
}

/**
 * Get the Redis client instance
 * @returns {Redis} - Redis client instance
 * @throws {Error} - If Redis is not initialized
 */
function getRedisClient() {
  if (!redisClient) {
    throw new Error('Redis client not initialized. Call initializeRedis() first.');
  }
  return redisClient;
}

/**
 * Create a Redis mock for graceful fallback when Redis is unavailable
 * @returns {Object} - Mock Redis client
 */
function createRedisMock() {
  logger.warn('Creating Redis mock - data will not persist across restarts');
  
  const storage = new Map();
  
  return {
    async get(key) {
      logger.debug(`MOCK: GET ${key}`);
      return storage.get(key) || null;
    },
    
    async set(key, value, ...args) {
      logger.debug(`MOCK: SET ${key}`);
      storage.set(key, value);
      
      // Handle expiry if EX option is provided
      if (args.includes('EX')) {
        const exIndex = args.indexOf('EX');
        if (exIndex < args.length - 1) {
          const seconds = args[exIndex + 1];
          setTimeout(() => {
            if (storage.get(key) === value) {
              storage.delete(key);
            }
          }, seconds * 1000);
        }
      }
      
      return 'OK';
    },
    
    async del(key) {
      logger.debug(`MOCK: DEL ${key}`);
      return storage.delete(key) ? 1 : 0;
    },
    
    async ping() {
      return 'PONG';
    },
    
    // Add other methods as needed for basic functionality
    on() {}, // No-op for event handlers
  };
}

/**
 * Store data in Redis with automatic serialization
 * @param {string} key - Redis key
 * @param {any} data - Data to store
 * @param {number} [ttl=3600] - Time to live in seconds (default: 1 hour)
 * @returns {Promise<string>} - Redis response
 */
async function cacheData(key, data, ttl = 3600) {
  try {
    const serialized = JSON.stringify(data);
    
    // Also store in memory cache for fallback
    memoryCache.set(key, data);
    memoryCacheExpiry.set(key, Date.now() + (ttl * 1000));
    
    try {
      // Try to store in Redis
      const redis = getRedisClient();
      return await redis.set(key, serialized, 'EX', ttl);
    } catch (redisError) {
      logger.error('Redis error during cache write, using memory cache only', { 
        key, 
        error: redisError.message 
      });
      return 'OK (Memory Cache)';
    }
  } catch (error) {
    logger.error('Error caching data', { key, error: error.message });
    throw error;
  }
}

/**
 * Retrieve data from Redis with automatic deserialization
 * Falls back to in-memory cache if Redis fails
 * @param {string} key - Redis key
 * @returns {Promise<any>} - Deserialized data or null if not found
 */
async function getCachedData(key) {
  try {
    // Try Redis first
    const redis = getRedisClient();
    const data = await redis.get(key);
    
    if (data) {
      try {
        // Found in Redis, also update memory cache as backup
        const parsed = JSON.parse(data);
        memoryCache.set(key, parsed);
        memoryCacheExpiry.set(key, Date.now() + MEMORY_CACHE_TTL);
        return parsed;
      } catch (parseError) {
        logger.error('Error parsing Redis data', { key, error: parseError.message });
        // Fall back to memory cache
      }
    }
    
    // Not found in Redis or parse error, try memory cache
    if (memoryCache.has(key)) {
      const expiry = memoryCacheExpiry.get(key);
      if (expiry && expiry > Date.now()) {
        logger.info('Memory cache hit for key', { key });
        return memoryCache.get(key);
      } else if (expiry) {
        // Expired item, clean up
        memoryCache.delete(key);
        memoryCacheExpiry.delete(key);
      }
    }
    
    // Not found anywhere
    return null;
  } catch (error) {
    // Redis error, try memory cache fallback
    logger.warn('Redis error during get, using memory cache fallback', { key, error: error.message });
    
    // Check if we have it in memory cache and it's not expired
    if (memoryCache.has(key)) {
      const expiry = memoryCacheExpiry.get(key);
      if (expiry && expiry > Date.now()) {
        logger.info('Memory cache hit for key during Redis failure', { key });
        return memoryCache.get(key);
      } else if (expiry) {
        // Expired item, clean up
        memoryCache.delete(key);
        memoryCacheExpiry.delete(key);
      }
    }
    
    // Not in memory cache or expired
    return null;
  }
}

/**
 * Invalidate cached data
 * @param {string} key - Redis key or pattern
 * @returns {Promise<number>} - Number of keys removed
 */
async function invalidateCache(key) {
  try {
    let redisCount = 0;
    let memoryCount = 0;
    
    // Clear from memory cache first (always succeeds)
    if (key.includes('*')) {
      // Pattern matching for memory cache
      const pattern = new RegExp('^' + key.replace(/\*/g, '.*') + '$');
      
      for (const cacheKey of memoryCache.keys()) {
        if (pattern.test(cacheKey)) {
          memoryCache.delete(cacheKey);
          memoryCacheExpiry.delete(cacheKey);
          memoryCount++;
        }
      }
    } else {
      // Simple key delete for memory cache
      if (memoryCache.has(key)) {
        memoryCache.delete(key);
        memoryCacheExpiry.delete(key);
        memoryCount = 1;
      }
    }
    
    try {
      // Try Redis invalidation
      const redis = getRedisClient();
      
      // If key contains wildcard, use scan to find matching keys
      if (key.includes('*')) {
        const stream = redis.scanStream({
          match: key,
          count: 100
        });
        
        redisCount = await new Promise((resolve, reject) => {
          let count = 0;
          
          stream.on('data', async (keys) => {
            if (keys.length) {
              const pipeline = redis.pipeline();
              keys.forEach(k => pipeline.del(k));
              const results = await pipeline.exec();
              count += results.reduce((acc, [err, res]) => acc + (err ? 0 : res), 0);
            }
          });
          
          stream.on('end', () => {
            resolve(count);
          });
          
          stream.on('error', (err) => {
            reject(err);
          });
        });
      } else {
        // Simple key delete
        redisCount = await redis.del(key);
      }
    } catch (redisError) {
      logger.error('Redis error during cache invalidation, memory cache cleared only', { 
        key, 
        error: redisError.message,
        memoryKeysRemoved: memoryCount
      });
      return memoryCount;
    }
    
    // Return total keys removed
    const totalRemoved = redisCount + memoryCount;
    logger.info('Cache invalidation complete', { 
      key, 
      redisKeysRemoved: redisCount,
      memoryKeysRemoved: memoryCount,
      totalRemoved
    });
    
    return totalRemoved;
  } catch (error) {
    logger.error('Error invalidating cache', { key, error: error.message });
    throw error;
  }
}

/**
 * Get memory cache stats for metrics
 * @returns {Object} - Memory cache statistics
 */
function getMemoryCacheStats() {
  const now = Date.now();
  let activeItems = 0;
  let expiredItems = 0;
  
  // Count active and expired items
  for (const [key, expiry] of memoryCacheExpiry.entries()) {
    if (expiry > now) {
      activeItems++;
    } else {
      expiredItems++;
      // Clean up expired items as we go
      memoryCache.delete(key);
      memoryCacheExpiry.delete(key);
    }
  }
  
  return {
    size: memoryCache.size,
    activeItems,
    expiredItems
  };
}

module.exports = {
  initializeRedis,
  getRedisClient,
  cacheData,
  getCachedData,
  invalidateCache,
  getMemoryCacheStats
};