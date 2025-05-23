// k6 performance test script for agent-core retrieval endpoint
import http from 'k6/http';
import { check, sleep } from 'k6';
import { SharedArray } from 'k6/data';
import { Rate } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');

// Load queries from file
const queries = new SharedArray('queries', function () {
  return open('./queryset.txt').split('\n').filter(Boolean);
});

export const options = {
  vus: 25,              // 25 virtual users
  duration: '2m',       // Run for 2 minutes
  thresholds: {
    http_req_failed: ['rate<0.01'],      // Error rate < 1%
    http_req_duration: ['p(95)<300'],    // p95 < 300ms
    errors: ['rate<0.01'],               // Custom error metric
  },
};

export default function () {
  // Pick a random query
  const query = queries[Math.floor(Math.random() * queries.length)];

  // Prepare request
  const payload = JSON.stringify({
    query: query,
    top_k: 5  // Default to 5 results
  });

  const params = {
    headers: {
      'Content-Type': 'application/json',
    },
    timeout: '3s',  // Match the 3-second server timeout
  };

  // Make request
  const res = http.post('http://localhost:8080/v1/query', payload, params);

  // Validate response
  const success = check(res, {
    'status is 200': (r) => r.status === 200,
    'response has answer': (r) => {
      try {
        const body = JSON.parse(r.body);
        return body.answer && body.answer.length > 0;
      } catch (e) {
        return false;
      }
    },
    'response has citations': (r) => {
      try {
        const body = JSON.parse(r.body);
        return Array.isArray(body.citations);
      } catch (e) {
        return false;
      }
    },
    'response time < 300ms': (r) => r.timings.duration < 300,
  });

  // Track errors
  errorRate.add(!success);

  // Sleep to control request rate (~10 QPS with 25 VUs)
  sleep(0.1);
}

export function handleSummary(data) {
  return {
    'stdout': textSummary(data, { indent: ' ', enableColors: true }),
    'perf/k6-results.json': JSON.stringify(data),
  };
}
