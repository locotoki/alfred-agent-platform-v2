import http from 'k6/http';
import { sleep, check } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('error_rate');
const reqDuration = new Trend('req_duration');
const cacheHits = new Rate('cache_hit_rate');

// Test configuration
export const options = {
  vus: 50,             // Virtual Users
  duration: '2m',      // Test duration
  thresholds: {
    // Test fails if p99 latency exceeds 800ms
    'http_req_duration{p(99)}': ['value<800'],
    // Test fails if error rate exceeds 2%
    'error_rate': ['value<0.02'],
    // Test fails if cache hit rate falls below 60% after warmup
    'cache_hit_rate{stage:main}': ['value>0.6'],
  },
  // Test stages
  stages: [
    { duration: '15s', target: 10 },   // Ramp-up to 10 users
    { duration: '30s', target: 30 },   // Ramp-up to 30 users
    { duration: '1m', target: 50 },    // Ramp-up to 50 users
    { duration: '15s', target: 0 }     // Ramp-down to 0 users
  ],
};

// Test setup
export function setup() {
  // Warm up the cache with a few queries
  const categories = ['Gaming', 'Education', 'Entertainment', 'Howto & Style', 'Science & Technology'];
  const queries = ['mobile', 'tutorial', 'game', 'cooking', 'makeup', 'tech', 'review'];

  console.log('Warming up cache...');

  for (const category of categories) {
    for (let i = 0; i < 2; i++) {
      const query = queries[Math.floor(Math.random() * queries.length)];
      http.post('http://localhost:3020/api/youtube/niche-scout', JSON.stringify({
        query: query,
        category: category,
        subcategories: [],
        timeRange: 'Last 30 days',
        demographics: 'All'
      }), {
        headers: {
          'Content-Type': 'application/json',
        },
      });
    }
  }

  // Wait for cache to populate
  sleep(2);

  return {
    categories: categories,
    queries: queries
  };
}

// Test execution
export default function(data) {
  // Select random category and query
  const category = data.categories[Math.floor(Math.random() * data.categories.length)];
  const query = data.queries[Math.floor(Math.random() * data.queries.length)];

  // Randomly include subcategories
  let subcategories = [];
  if (Math.random() > 0.5) {
    switch (category) {
      case 'Gaming':
        subcategories = ['Mobile Gaming'];
        break;
      case 'Education':
        subcategories = ['Tutorials'];
        break;
      case 'Howto & Style':
        subcategories = ['Beauty'];
        break;
      default:
        // No subcategories
    }
  }

  // Execute the request
  const payload = JSON.stringify({
    query: query,
    category: category,
    subcategories: subcategories,
    timeRange: 'Last 30 days',
    demographics: 'All'
  });

  // Track metrics based on current stage
  const stage = (http.get('http://localhost:3020/metrics').status === 200) ? 'main' : 'warmup';
  const tags = { stage: stage };

  const start = new Date().getTime();
  const res = http.post('http://localhost:3020/api/youtube/niche-scout', payload, {
    headers: {
      'Content-Type': 'application/json',
    },
    tags: tags
  });
  const duration = new Date().getTime() - start;

  reqDuration.add(duration);

  // Check if request was successful
  const success = check(res, {
    'status is 200': (r) => r.status === 200,
    'has niches': (r) => {
      try {
        const body = JSON.parse(r.body);
        return body.niches && body.niches.length > 0;
      } catch (e) {
        return false;
      }
    }
  });

  errorRate.add(!success, tags);

  // Check for cache hit
  const isCacheHit = res.headers['X-Cache'] === 'HIT' ||
                   (JSON.parse(res.body).meta && JSON.parse(res.body).meta.cache_hit === true);
  cacheHits.add(isCacheHit, tags);

  // Random pause between requests
  sleep(Math.random() * 1 + 0.5);
}

// Test teardown
export function teardown() {
  console.log('Test completed');
}
