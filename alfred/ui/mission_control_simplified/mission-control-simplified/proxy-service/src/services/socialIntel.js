/**
 * Social Intelligence API client
 *
 * Handles communication with the Social Intelligence API.
 */

const axios = require('axios');
const { getConfig } = require('../config');
const { createLogger } = require('../utils/logger');

const logger = createLogger('social-intel');

/**
 * Create axios instance for Social Intelligence API
 * @returns {axios.AxiosInstance} - Configured axios instance
 */
function createApiClient() {
  const config = getConfig();
  const { host, port, timeout, apiKey } = config.socialIntel;

  const baseURL = `${host}:${port}`;

  logger.info(`Creating Social Intelligence API client with baseURL: ${baseURL}`);

  // Create headers with authentication if API key is provided
  const headers = {
    'Content-Type': 'application/json'
  };

  if (apiKey) {
    logger.info('Using API key authentication for Social Intelligence API');
    headers['x-api-key'] = apiKey;
  } else {
    logger.warn('No API key provided for Social Intelligence API');
  }

  return axios.create({
    baseURL,
    timeout,
    headers
  });
}

/**
 * Call Social Intelligence API
 * @param {string} endpoint - API endpoint
 * @param {Object} data - Request payload
 * @returns {Promise<Object>} - API response data
 */
async function callSocialIntelApi(endpoint, data) {
  try {
    const apiClient = createApiClient();

    logger.info(`Calling Social Intelligence API: ${endpoint}`, {
      data: data ? JSON.stringify(data).substring(0, 100) + '...' : null
    });

    const startTime = Date.now();
    const response = await apiClient.post(endpoint, data);
    const responseTime = Date.now() - startTime;

    logger.info(`Social Intelligence API response received in ${responseTime}ms`, {
      statusCode: response.status
    });

    return response.data;
  } catch (error) {
    logger.error('Error calling Social Intelligence API', {
      endpoint,
      error: error.message,
      status: error.response ? error.response.status : null
    });

    // Check if mock fallback is enabled
    const config = getConfig();
    if (config.socialIntel.enableMockFallback !== false) {
      logger.info('Using mock fallback for Social Intelligence API');
      return generateMockResponse(endpoint, data);
    }

    throw error;
  }
}

/**
 * Check if Social Intelligence API is available
 * @returns {Promise<boolean>} - Whether the API is available
 */
async function checkSocialIntelStatus() {
  try {
    const apiClient = createApiClient();
    const response = await apiClient.get('/status');
    return response.status === 200;
  } catch (error) {
    logger.error('Error checking Social Intelligence API status', {
      error: error.message
    });
    return false;
  }
}

/**
 * Generate mock response for fallback
 * @param {string} endpoint - API endpoint
 * @param {Object} data - Request payload
 * @returns {Object} - Mock response
 */
function generateMockResponse(endpoint, data) {
  logger.warn('Generating mock response for API endpoint', { endpoint });

  // Different mock responses based on endpoint
  if (endpoint === '/api/youtube/niche-scout') {
    const query = data.query || '';
    const category = data.category || 'All';

    return {
      date: new Date().toISOString().split('T')[0],
      query: query,
      category: category,
      niches: [
        {
          name: 'Mobile Gaming',
          growth_rate: 87.5,
          shorts_friendly: true,
          competition_level: 'Medium',
          viewer_demographics: {
            age_groups: ['18-24', '25-34'],
            gender_split: { male: 65, female: 35 }
          },
          trending_topics: [
            'Game development tutorials',
            'Mobile gaming optimization',
            'Indie game showcases'
          ],
          top_channels: [
            { name: 'MobileGamerPro', subs: 2800000 },
            { name: 'GameHubMobile', subs: 1400000 }
          ]
        },
        {
          name: 'Game Development',
          growth_rate: 72.1,
          shorts_friendly: false,
          competition_level: 'Low',
          viewer_demographics: {
            age_groups: ['25-34', '35-44'],
            gender_split: { male: 80, female: 20 }
          },
          trending_topics: [
            'Unity tutorials',
            'Game design principles',
            'Indie publishing strategies'
          ],
          top_channels: [
            { name: 'GameDevHQ', subs: 1200000 },
            { name: 'CodeMonkey', subs: 980000 }
          ]
        },
        {
          name: 'Indie Games',
          growth_rate: 65.3,
          shorts_friendly: true,
          competition_level: 'Medium',
          viewer_demographics: {
            age_groups: ['18-24', '25-34'],
            gender_split: { male: 70, female: 30 }
          },
          trending_topics: [
            'Indie game reviews',
            'Game jams',
            'Pixel art tutorials'
          ],
          top_channels: [
            { name: 'IndieGameSpotlight', subs: 850000 },
            { name: 'PixelPerfect', subs: 720000 }
          ]
        }
      ],
      _mock: true
    };
  }

  // Default mock response
  return {
    status: 'completed',
    result: {
      message: 'Mock response from Social Intelligence API'
    },
    _mock: true
  };
}

module.exports = {
  callSocialIntelApi,
  checkSocialIntelStatus
};
