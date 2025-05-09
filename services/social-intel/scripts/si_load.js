import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';
import { SharedArray } from 'k6/data';
import { scenario } from 'k6/execution';
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.2/index.js';
import { writeFileSync } from 'k6/experimental/fs';

// Define custom metrics
const errorRate = new Rate('error_rate');
const nicheScoutLatency = new Trend('niche_scout_latency');
const hotNichesLatency = new Trend('hot_niches_latency');
const seedToBlueprintLatency = new Trend('seed_to_blueprint_latency');

// Test configuration
export const options = {
  scenarios: {
    niche_scout_load: {
      executor: 'ramping-vus',
      startVUs: 1,
      stages: [
        { duration: '10s', target: 5 },
        { duration: '30s', target: 10 },
        { duration: '20s', target: 15 },
        { duration: '10s', target: 0 },
      ],
      gracefulRampDown: '5s',
    },
  },
  thresholds: {
    'error_rate': ['rate<0.05'],                      // Error rate should be less than 5%
    'niche_scout_latency': ['p95<800'],              // 95% of requests should be under 800ms
    'hot_niches_latency': ['p95<400'],               // 95% of requests should be under 400ms
    'seed_to_blueprint_latency': ['p95<1000'],       // 95% of requests should be under 1000ms
    'http_req_duration': ['p95<1000', 'max<2000'],   // Global thresholds
  },
};

// Sample categories for testing (could be expanded)
const categories = [
  "Technology",
  "Gaming",
  "Health",
  "Finance",
  "Education",
  "Entertainment",
  "Fitness",
  "Food",
  "Travel",
  "Fashion"
];

// Sample queries for testing (could be expanded)
const queries = [
  "how to",
  "best ways",
  "tutorial",
  "review",
  "guide",
  "tips",
  "basics",
  "beginners",
  "advanced",
  "masterclass"
];

// Combine categories and queries
function generateQueries() {
  const result = [];
  categories.forEach(category => {
    queries.forEach(query => {
      result.push({ category, query });
    });
  });
  return result;
}

const testQueries = new SharedArray('test_queries', generateQueries);

export default function () {
  // Test /niche-scout endpoint
  {
    const randomIndex = Math.floor(Math.random() * testQueries.length);
    const { category, query } = testQueries[randomIndex];
    
    const nicheScoutResponse = http.get(
      `http://localhost:9000/niche-scout?category=${encodeURIComponent(category)}&query=${encodeURIComponent(query)}`,
      { tags: { name: 'niche-scout' } }
    );
    
    // Record metrics
    nicheScoutLatency.add(nicheScoutResponse.timings.duration);
    errorRate.add(nicheScoutResponse.status !== 200);
    
    // Assert response
    check(nicheScoutResponse, {
      'niche-scout status is 200': (r) => r.status === 200,
      'niche-scout response has niches': (r) => r.json().niches && r.json().niches.length > 0,
    });
  }
  
  // Test /hot-niches endpoint
  {
    const hotNichesResponse = http.get(
      'http://localhost:9000/hot-niches?limit=10',
      { tags: { name: 'hot-niches' } }
    );
    
    // Record metrics
    hotNichesLatency.add(hotNichesResponse.timings.duration);
    errorRate.add(hotNichesResponse.status !== 200);
    
    // Assert response
    check(hotNichesResponse, {
      'hot-niches status is 200': (r) => r.status === 200,
      'hot-niches response has niches': (r) => r.json().niches && r.json().niches.length > 0,
    });
  }
  
  // Test /seed-to-blueprint endpoint
  {
    const seedPhrase = `Test Seed ${Date.now()}`;
    const seedToBlueprintResponse = http.post(
      'http://localhost:9000/seed-to-blueprint',
      JSON.stringify({ seed_phrase: seedPhrase }),
      { headers: { 'Content-Type': 'application/json' }, tags: { name: 'seed-to-blueprint' } }
    );
    
    // Record metrics
    seedToBlueprintLatency.add(seedToBlueprintResponse.timings.duration);
    errorRate.add(seedToBlueprintResponse.status !== 200);
    
    // Assert response
    check(seedToBlueprintResponse, {
      'seed-to-blueprint status is 200': (r) => r.status === 200,
      'seed-to-blueprint has channel info': (r) => r.json().channel_info && r.json().channel_info.title,
    });
  }
  
  sleep(1);
}

// Export results to file at the end of the test
export function handleSummary(data) {
  // Save JSON results for later analysis
  writeFileSync('k6-results.json', JSON.stringify(data));
  
  // Return text summary for console output
  return {
    stdout: textSummary(data, { indent: ' ', enableColors: true }),
  };
}