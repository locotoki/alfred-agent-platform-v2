/**
 * Unit tests for the cache invalidation endpoint
 */

const { describe, it, expect, beforeEach, afterEach, jest: jestObject } = require('@jest/globals');
const request = require('supertest');
const express = require('express');
const crypto = require('crypto');

// Mock dependencies
jest.mock('../../src/services/redis', () => ({
  invalidateCache: jest.fn().mockResolvedValue(5),
  getMemoryCacheStats: jest.fn().mockReturnValue({ size: 10, activeItems: 5 })
}));

jest.mock('../../src/utils/logger', () => ({
  createLogger: jest.fn().mockReturnValue({
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn()
  })
}));

jest.mock('../../src/services/metrics', () => ({
  recordMetrics: jest.fn()
}));

jest.mock('../../src/config', () => ({
  getConfig: jest.fn().mockReturnValue({
    featureFlags: {
      proxyEnabled: true,
      metricsEnabled: true
    },
    cache: {
      enabled: true,
      ttl: 3600
    }
  }),
  updateConfig: jest.fn()
}));

// Setup test environment
describe('Cache Invalidation Endpoint', () => {
  let app;
  let router;
  const TEST_TOKEN = crypto.randomBytes(24).toString('hex');
  const invalidateCache = require('../../src/services/redis').invalidateCache;
  const recordMetrics = require('../../src/services/metrics').recordMetrics;
  
  beforeEach(() => {
    process.env.CACHE_BUST_TOKEN = TEST_TOKEN;
    
    // Reset mock call history
    jestObject.clearAllMocks();
    
    // Create a minimal Express app for testing
    app = express();
    app.use(express.json());
    
    // Import the router directly
    router = require('../../src/routes/index');
    app.use('/', router);
  });
  
  afterEach(() => {
    delete process.env.CACHE_BUST_TOKEN;
  });
  
  it('should reject requests without a token', async () => {
    const response = await request(app)
      .delete('/cache');
    
    expect(response.status).toBe(401);
    expect(response.body.error).toBe('Unauthorized');
    expect(invalidateCache).not.toHaveBeenCalled();
  });
  
  it('should reject requests with invalid tokens', async () => {
    const response = await request(app)
      .delete('/cache?token=invalid-token');
    
    expect(response.status).toBe(401);
    expect(response.body.error).toBe('Unauthorized');
    expect(invalidateCache).not.toHaveBeenCalled();
  });
  
  it('should invalidate all cache with valid token and no key', async () => {
    const response = await request(app)
      .delete(`/cache?token=${TEST_TOKEN}`);
    
    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.keysRemoved).toBe(5);
    expect(invalidateCache).toHaveBeenCalledWith('*');
    expect(recordMetrics).toHaveBeenCalledWith('redis_operation', expect.objectContaining({
      operation: 'invalidate',
      result: 'success'
    }));
  });
  
  it('should invalidate specific key pattern with valid token', async () => {
    const keyPattern = 'test:*';
    const response = await request(app)
      .delete(`/cache/${keyPattern}?token=${TEST_TOKEN}`);
    
    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.message).toContain(keyPattern);
    expect(invalidateCache).toHaveBeenCalledWith(keyPattern);
  });
  
  it('should handle redis errors gracefully', async () => {
    // Make invalidateCache throw an error
    invalidateCache.mockRejectedValueOnce(new Error('Redis connection error'));
    
    const response = await request(app)
      .delete(`/cache?token=${TEST_TOKEN}`);
    
    expect(response.status).toBe(500);
    expect(response.body.error).toBe('Internal Server Error');
    expect(recordMetrics).toHaveBeenCalledWith('error', expect.objectContaining({
      endpoint: '/cache'
    }));
  });
});