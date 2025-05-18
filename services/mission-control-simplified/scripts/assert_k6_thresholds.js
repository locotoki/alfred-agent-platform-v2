// scripts/assert_k6_thresholds.js
const fs = require('fs');

try {
  // Read and parse the k6 results
  const result = JSON.parse(fs.readFileSync('result.json'));

  // Extract metrics
  const p99 = result.metrics.http_req_duration.values['p(99)'];
  const errorRate = (1 - result.metrics.checks.rate) * 100;

  // Log results
  console.log(`p99 Latency: ${p99.toFixed(2)}ms (threshold: 800ms)`);
  console.log(`Error Rate: ${errorRate.toFixed(2)}% (threshold: 3%)`);

  // Check against thresholds
  let passed = true;

  if (p99 >= 800) {
    console.error('❌ FAILED: p99 latency exceeds 800ms threshold');
    passed = false;
  }

  if (errorRate >= 3) {
    console.error('❌ FAILED: Error rate exceeds 3% threshold');
    passed = false;
  }

  if (passed) {
    console.log('✅ PASSED: All thresholds met');
    process.exit(0);
  } else {
    process.exit(1);
  }
} catch (error) {
  console.error('Error processing k6 results:', error);
  process.exit(1);
}
