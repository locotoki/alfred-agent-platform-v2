/**
 * Integration tests for proxy service API
 */

const request = require('supertest');
const path = require('path');
const fs = require('fs');
const dotenvPath = path.resolve(__dirname, '../../.env.test');

// Load test environment variables if available
if (fs.existsSync(dotenvPath)) {
  require('dotenv').config({ path: dotenvPath });
}

// Mock redis client
jest.mock('../../src/services/redis', () => {
  const mockStorage = new Map();
  
  return {
    initializeRedis: jest.fn().mockResolvedValue(true),
    getRedisClient: jest.fn(() => ({
      get: jest.fn((key) => Promise.resolve(mockStorage.get(key))),
      set: jest.fn((key, value) => {
        mockStorage.set(key, value);
        return Promise.resolve('OK');
      }),
      del: jest.fn((key) => {
        return Promise.resolve(mockStorage.delete(key) ? 1 : 0);
      })
    })),
    cacheData: jest.fn((key, data, ttl) => {
      mockStorage.set(key, JSON.stringify(data));
      return Promise.resolve('OK');
    }),
    getCachedData: jest.fn((key) => {
      const data = mockStorage.get(key);
      return Promise.resolve(data ? JSON.parse(data) : null);
    }),
    invalidateCache: jest.fn((key) => {
      return Promise.resolve(mockStorage.delete(key) ? 1 : 0);
    })
  };
});

// Mock Social Intelligence API client
jest.mock('../../src/services/socialIntel', () => {
  return {
    callSocialIntelApi: jest.fn().mockImplementation((endpoint, data) => {
      // Mock API response
      return Promise.resolve({
        date: new Date().toISOString().split('T')[0],
        query: null, // simulate API not respecting query
        category: null, // simulate API not respecting category
        niches: [
          {
            name: 'Content Creation',
            growth_rate: 85,
            shorts_friendly: true,
            competition_level: 'Medium',
            viewer_demographics: {
              age_groups: ['18-24', '25-34'],
              gender_split: { male: 60, female: 40 }
            },
            trending_topics: [
              'Video editing tips',
              'Audience growth strategies',
              'Monetization methods'
            ],
            top_channels: [
              { name: 'CreatorHub', subs: 2500000 },
              { name: 'ContentMastery', subs: 1800000 }
            ]
          },
          {
            name: 'Educational Videos',
            growth_rate: 75,
            shorts_friendly: false,
            competition_level: 'Low',
            viewer_demographics: {
              age_groups: ['25-34', '35-44'],
              gender_split: { male: 55, female: 45 }
            },
            trending_topics: [
              'Online course creation',
              'Teaching methodologies',
              'Student engagement'
            ],
            top_channels: [
              { name: 'LearnDaily', subs: 1900000 },
              { name: 'EduMaster', subs: 1200000 }
            ]
          }
        ]
      });
    }),
    checkSocialIntelStatus: jest.fn().mockResolvedValue(true)
  };
});

// Mock metrics service
jest.mock('../../src/services/metrics', () => {
  return {
    recordMetrics: jest.fn(),
    getMetricsRegistry: jest.fn(() => ({
      metrics: () => 'test_metric 1'
    }))
  };
});

// Import the app after all mocks are set up
const app = require('../../src/index');

describe('Proxy Service API', () => {
  describe('GET /status', () => {
    test('returns health status', async () => {
      const response = await request(app).get('/status');
      expect(response.status).toBe(200);
      expect(response.body.status).toBe('healthy');
    });
  });

  describe('GET /config', () => {
    test('returns configuration', async () => {
      const response = await request(app).get('/config');
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('transformation');
    });
  });

  describe('POST /api/youtube/niche-scout', () => {
    test('transforms API response', async () => {
      const testParams = {
        query: 'gaming',
        category: 'Entertainment',
        subcategories: ['Mobile Gaming'],
        timeRange: 'Last 30 days',
        demographics: 'All'
      };

      const response = await request(app)
        .post('/api/youtube/niche-scout')
        .send(testParams);

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('niches');
      expect(response.body.query).toBe('gaming');
      expect(response.body.category).toBe('Entertainment');
      expect(response.body.meta).toHaveProperty('transformation_version');
      expect(response.body.meta).toHaveProperty('relevance_score');
    });

    test('handles missing query gracefully', async () => {
      const testParams = {
        category: 'Entertainment',
        timeRange: 'Last 30 days'
      };

      const response = await request(app)
        .post('/api/youtube/niche-scout')
        .send(testParams);

      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('niches');
      expect(response.body.category).toBe('Entertainment');
    });
  });
});