/**
 * Configuration management for the proxy service
 * 
 * Manages loading configuration from environment variables and Redis
 * with support for dynamic updates.
 */

const { getRedisClient } = require('./services/redis');
const { createLogger } = require('./utils/logger');

const logger = createLogger('config');

// Default configuration values
const DEFAULT_CONFIG = {
  // Social Intelligence API config
  socialIntel: {
    host: process.env.SOCIAL_INTEL_HOST || 'http://localhost',
    port: parseInt(process.env.SOCIAL_INTEL_PORT || '9000', 10),
    timeout: parseInt(process.env.API_TIMEOUT || '5000', 10),
    apiKey: process.env.SI_API_KEY || '',
    enableMockFallback: process.env.ENABLE_MOCK_FALLBACK !== 'false'
  },
  
  // Transformation config
  transformation: {
    similarityThreshold: parseFloat(process.env.SIMILARITY_THRESHOLD || '0.55'),
    defaultNicheCount: parseInt(process.env.DEFAULT_NICHE_COUNT || '5', 10),
    algorithmWeights: {
      levenshtein: parseFloat(process.env.WEIGHT_LEVENSHTEIN || '0.5'),
      jaccard: parseFloat(process.env.WEIGHT_JACCARD || '0.3'),
      jaroWinkler: parseFloat(process.env.WEIGHT_JARO_WINKLER || '0.2')
    }
  },
  
  // Caching config
  cache: {
    enabled: process.env.CACHE_ENABLED !== 'false',
    ttl: parseInt(process.env.CACHE_TTL || '3600', 10) // 1 hour default
  },
  
  // Feature flags
  featureFlags: {
    proxyEnabled: process.env.FEATURE_FLAG_PROXY_ENABLED !== 'false',
    metricsEnabled: process.env.FEATURE_FLAG_METRICS_ENABLED !== 'false'
  }
};

// Current active configuration
let activeConfig = { ...DEFAULT_CONFIG };

/**
 * Load configuration from Redis or use defaults
 * @returns {Promise<Object>} - The active configuration
 */
async function loadConfig() {
  try {
    const redis = getRedisClient();
    
    // Check if we have stored config in Redis
    const storedConfig = await redis.get('proxy:config');
    
    if (storedConfig) {
      // Parse and merge with defaults (to ensure all properties exist)
      const parsedConfig = JSON.parse(storedConfig);
      activeConfig = mergeConfigs(DEFAULT_CONFIG, parsedConfig);
      logger.info('Loaded configuration from Redis');
    } else {
      // Use default config
      activeConfig = { ...DEFAULT_CONFIG };
      logger.info('Using default configuration');
      
      // Store default config in Redis for future reference
      await redis.set('proxy:config', JSON.stringify(DEFAULT_CONFIG));
    }
    
    // Validate configuration
    validateConfig(activeConfig);
    
    return activeConfig;
  } catch (error) {
    logger.error('Error loading configuration', { error: error.message });
    return DEFAULT_CONFIG;
  }
}

/**
 * Update configuration and store in Redis
 * @param {Object} newConfig - New configuration values
 * @returns {Promise<Object>} - The updated active configuration
 */
async function updateConfig(newConfig) {
  try {
    // Merge with current config
    const updatedConfig = mergeConfigs(activeConfig, newConfig);
    
    // Validate configuration
    validateConfig(updatedConfig);
    
    // Store in Redis
    const redis = getRedisClient();
    await redis.set('proxy:config', JSON.stringify(updatedConfig));
    
    // Update active config
    activeConfig = updatedConfig;
    
    logger.info('Configuration updated and stored in Redis');
    return activeConfig;
  } catch (error) {
    logger.error('Error updating configuration', { error: error.message });
    throw error;
  }
}

/**
 * Get the current active configuration
 * @returns {Object} - The active configuration
 */
function getConfig() {
  return activeConfig;
}

/**
 * Merge configurations with deep object merge
 * @param {Object} target - Target configuration
 * @param {Object} source - Source configuration to merge
 * @returns {Object} - Merged configuration
 */
function mergeConfigs(target, source) {
  const output = { ...target };
  
  if (isObject(target) && isObject(source)) {
    Object.keys(source).forEach(key => {
      if (isObject(source[key])) {
        if (!(key in target)) {
          Object.assign(output, { [key]: source[key] });
        } else {
          output[key] = mergeConfigs(target[key], source[key]);
        }
      } else {
        Object.assign(output, { [key]: source[key] });
      }
    });
  }
  
  return output;
}

/**
 * Check if value is an object
 * @param {*} item - Value to check
 * @returns {boolean} - Whether the value is an object
 */
function isObject(item) {
  return (item && typeof item === 'object' && !Array.isArray(item));
}

/**
 * Validate configuration values
 * @param {Object} config - Configuration to validate
 * @throws {Error} - If configuration is invalid
 */
function validateConfig(config) {
  // Check similarity threshold
  if (config.transformation.similarityThreshold < 0 || config.transformation.similarityThreshold > 1) {
    throw new Error('Similarity threshold must be between 0 and 1');
  }
  
  // Check algorithm weights sum to 1.0
  const { levenshtein, jaccard, jaroWinkler } = config.transformation.algorithmWeights;
  const weightSum = levenshtein + jaccard + jaroWinkler;
  
  if (Math.abs(weightSum - 1.0) > 0.01) {
    throw new Error(`Algorithm weights must sum to 1.0, got ${weightSum}`);
  }
  
  // Check niche count is positive
  if (config.transformation.defaultNicheCount <= 0) {
    throw new Error('Default niche count must be positive');
  }
  
  // Check cache TTL is positive
  if (config.cache.ttl <= 0) {
    throw new Error('Cache TTL must be positive');
  }
}

module.exports = {
  loadConfig,
  updateConfig,
  getConfig
};