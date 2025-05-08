import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');

// Test configuration
export const options = {
  stages: [
    { duration: '30s', target: 10 },  // Ramp up to 10 users
    { duration: '1m', target: 50 },   // Ramp up to 50 users
    { duration: '2m', target: 50 },   // Stay at 50 users
    { duration: '30s', target: 0 },   // Ramp down to 0 users
  ],
  thresholds: {
    'http_req_duration': ['p(99)<800'], // 99% of requests must complete below 800ms
    'errors': ['rate<0.03'],            // Error rate must be less than 3%
  },
};

// Test setup
export function setup() {
  return {
    baseUrl: __ENV.BASE_URL || 'http://localhost:3007',
  };
}

// Main test function
export default function(data) {
  const baseUrl = data.baseUrl;
  
  // Test case 1: Niche-Scout workflow
  const payload1 = JSON.stringify({
    query: 'mobile',
    category: 'Gaming',
    subcategories: ['Mobile Gaming'],
    timeRange: 'Last 30 days',
    demographics: 'All'
  });
  
  const params = {
    headers: {
      'Content-Type': 'application/json',
    },
  };
  
  // Make request to Niche-Scout workflow
  const res1 = http.post(`${baseUrl}/api/workflows/niche-scout`, payload1, params);
  
  // Check if request was successful
  const success1 = check(res1, {
    'status is 200': (r) => r.status === 200,
    'has niches array': (r) => r.json().niches && Array.isArray(r.json().niches),
    'has at least 3 niches': (r) => r.json().niches && r.json().niches.length >= 3,
  });
  
  // Record errors
  errorRate.add(!success1);
  
  // Test case 2: Get API health check
  const res2 = http.get(`${baseUrl}/api/health`);
  
  // Check if health endpoint is working
  const success2 = check(res2, {
    'health check returns 200': (r) => r.status === 200,
    'health check reports healthy': (r) => r.json().status === 'healthy',
  });
  
  // Record errors
  errorRate.add(!success2);
  
  // Add some random sleep time between requests (100-500ms)
  sleep(Math.random() * 0.4 + 0.1);
}

// Test teardown
export function teardown(data) {
  // No teardown needed for this test
}