/**
 * This script analyzes k6 load test results and checks if performance thresholds were met
 * It's used in CI to fail the build if performance has regressed
 */

const fs = require('fs');
const path = require('path');

// Expected performance thresholds (same as in si_load.js)
const THRESHOLDS = {
  'error_rate': { max: 0.05, description: 'Error rate under 5%' },
  'niche_scout_latency': { p95: 800, description: '95% of niche-scout requests under 800ms' },
  'hot_niches_latency': { p95: 400, description: '95% of hot-niches requests under 400ms' },
  'seed_to_blueprint_latency': { p95: 1000, description: '95% of seed-to-blueprint requests under 1s' },
  'http_req_duration': { p95: 1000, max: 2000, description: 'Overall response time P95 under 1s, max under 2s' }
};

/**
 * Main analysis function that processes k6 results
 */
function analyzeResults() {
  try {
    // Read results file
    const resultsPath = path.join(__dirname, '..', 'k6-results.json');
    if (!fs.existsSync(resultsPath)) {
      console.error('❌ Results file not found. Did the k6 test complete successfully?');
      process.exit(1);
    }

    const results = JSON.parse(fs.readFileSync(resultsPath, 'utf8'));
    const metrics = results.metrics;
    
    console.log('📊 Social-Intel Load Test Results Analysis');
    console.log('=========================================');
    
    let failures = 0;
    
    // Analyze each threshold
    Object.entries(THRESHOLDS).forEach(([metricName, threshold]) => {
      // Skip if metric not found in results (rare but possible if test failed early)
      if (!metrics[metricName]) {
        console.log(`⚠️ Metric ${metricName} not found in results`);
        return;
      }
      
      const metricData = metrics[metricName];
      
      // Check error rate
      if (metricName === 'error_rate') {
        const rate = metricData.values.rate;
        const passed = rate <= threshold.max;
        
        console.log(`${passed ? '✅' : '❌'} ${threshold.description}`);
        console.log(`   Actual: ${(rate * 100).toFixed(2)}%, Expected: <${threshold.max * 100}%\n`);
        
        if (!passed) failures++;
      }
      // Check percentile thresholds (p95)
      else if (threshold.p95) {
        const p95Value = metricData.values['p(95)'];
        const passed = p95Value <= threshold.p95;
        
        console.log(`${passed ? '✅' : '❌'} ${threshold.description}`);
        console.log(`   Actual p95: ${p95Value.toFixed(2)}ms, Expected: <${threshold.p95}ms\n`);
        
        if (!passed) failures++;
      }
      // Check max thresholds
      if (threshold.max && metricName !== 'error_rate') {
        const maxValue = metricData.values.max;
        const passed = maxValue <= threshold.max;
        
        console.log(`${passed ? '✅' : '❌'} ${threshold.description} (max)`);
        console.log(`   Actual max: ${maxValue.toFixed(2)}ms, Expected: <${threshold.max}ms\n`);
        
        if (!passed) failures++;
      }
    });
    
    // Provide summary and exit with appropriate code
    console.log('=========================================');
    if (failures > 0) {
      console.log(`❌ Found ${failures} performance issues that exceed thresholds`);
      console.log('   This PR may cause performance regression and should be reviewed');
      process.exit(1);
    } else {
      console.log('✅ All performance thresholds passed!');
      process.exit(0);
    }
    
  } catch (error) {
    console.error('❌ Error analyzing results:', error);
    process.exit(1);
  }
}

// Run the analysis
analyzeResults();