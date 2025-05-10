/**
 * API routes for the proxy service
 */

const express = require('express');
const { createLogger } = require('../utils/logger');
const { getConfig } = require('../config');
const { callSocialIntelApi } = require('../services/socialIntel');
const { transformNicheScout } = require('../transformers/nicheScout');
const { getCachedData, cacheData } = require('../services/redis');
const { recordMetrics } = require('../services/metrics');

const router = express.Router();
const logger = createLogger('api-routes');

/**
 * Niche-Scout API endpoint
 * - Proxies requests to Social Intelligence API
 * - Applies transformation to ensure relevance
 * - Caches results
 * - Records metrics
 */
router.post('/youtube/niche-scout', async (req, res) => {
  const startTime = Date.now();
  const config = getConfig();
  
  try {
    logger.info('Niche-Scout request received', { params: req.body });
    
    // Extract request parameters
    const { query, category, subcategories, timeRange, demographics } = req.body;
    
    // Generate cache key
    const cacheKey = `niche-scout:${query || ''}:${category || ''}:${JSON.stringify(subcategories || [])}`;
    
    // Check cache if enabled
    if (config.cache.enabled) {
      const cachedData = await getCachedData(cacheKey);
      
      if (cachedData) {
        logger.info('Cache hit for Niche-Scout request', { cacheKey });
        
        // Add cache hit information to response
        cachedData.meta = cachedData.meta || {};
        cachedData.meta.cache_hit = true;
        
        // Record metrics for cache hit
        recordMetrics('cache_hit', {
          query,
          category,
          responseTime: Date.now() - startTime
        });
        
        return res.json(cachedData);
      }
      
      logger.info('Cache miss for Niche-Scout request', { cacheKey });
    }
    
    // Call Social Intelligence API
    const apiStartTime = Date.now();
    const apiResponse = await callSocialIntelApi('/api/youtube/niche-scout', req.body);
    const apiEndTime = Date.now();
    const apiResponseTime = apiEndTime - apiStartTime;
    
    logger.info('Social Intelligence API response received', { 
      responseTime: apiResponseTime,
      status: apiResponse ? 'success' : 'error'
    });
    
    // Transform the response if proxy is enabled
    let transformedData;
    if (config.featureFlags.proxyEnabled) {
      const transformStartTime = Date.now();
      
      transformedData = await transformNicheScout(apiResponse, req.body, {
        apiResponseTime
      });
      
      const transformEndTime = Date.now();
      const transformTime = transformEndTime - transformStartTime;
      
      logger.info('Transformation completed', { transformTime });
      
      // Add metadata
      transformedData.meta = transformedData.meta || {};
      transformedData.meta.transformation_version = 'phase1-v1';
      transformedData.meta.processing_time_ms = Date.now() - startTime;
      transformedData.meta.cache_hit = false;
      
      // Cache the transformed result if caching is enabled
      if (config.cache.enabled) {
        await cacheData(cacheKey, transformedData, config.cache.ttl);
        logger.info('Cached Niche-Scout response', { cacheKey, ttl: config.cache.ttl });
      }
    } else {
      // If proxy is disabled, return the original API response
      transformedData = apiResponse;
      
      // Add metadata
      transformedData.meta = transformedData.meta || {};
      transformedData.meta.processing_time_ms = Date.now() - startTime;
      transformedData.meta.cache_hit = false;
      transformedData.meta.transformation_version = 'none';
    }
    
    // Record metrics
    recordMetrics('api_request', {
      query,
      category,
      apiResponseTime,
      totalTime: Date.now() - startTime,
      transformationApplied: config.featureFlags.proxyEnabled
    });
    
    // Return the response
    return res.json(transformedData);
  } catch (error) {
    logger.error('Error processing Niche-Scout request', { error: error.message, stack: error.stack });
    
    // Record error metrics
    recordMetrics('error', {
      error: error.message,
      responseTime: Date.now() - startTime
    });
    
    // Return error response
    return res.status(500).json({
      error: 'Failed to process Niche-Scout request',
      message: error.message
    });
  }
});

module.exports = router;