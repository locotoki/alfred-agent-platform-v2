/**
 * Manual test cases for Phase 0 of Niche-Scout ↔ Social-Intel Integration
 * 
 * This script tests the specific test cases required in the implementation guide:
 * 1. "mobile" in "Gaming" category
 * 2. "tutorial" in "Education" category  
 * 3. "makeup" in "Howto & Style" category
 * 4. Empty query with category only
 * 5. Query with no category (set to "All")
 *
 * Edge cases:
 * - Very short query (1-2 characters)
 * - Very long query (50+ characters)
 * - Special characters in query
 * - Non-existent category
 */

const { 
  getMockNichesForCategory, 
  calculateRelevanceMetrics,
  stringSimilarity,
  SIMILARITY_THRESHOLD
} = require('./integrate-with-social-intel');

// Constants
const PERFORMANCE_TEST_ITERATIONS = 10;

// Helper function to format milliseconds
const formatMs = ms => `${ms.toFixed(2)}ms`;

// Helper function to format percentage
const formatPercentage = val => `${(val * 100).toFixed(1)}%`;

// Helper function to calculate statistics
function calculateStats(values) {
  if (!values || values.length === 0) return { min: 0, max: 0, avg: 0, p95: 0 };
  
  values.sort((a, b) => a - b);
  const sum = values.reduce((acc, val) => acc + val, 0);
  const avg = sum / values.length;
  const min = values[0];
  const max = values[values.length - 1];
  const p95Index = Math.ceil(values.length * 0.95) - 1;
  const p95 = values[p95Index];
  
  return { min, max, avg, p95 };
}

// Helper function to check and display relevance
function checkRelevance(query, category, printDetails = true) {
  console.log(`\nTesting "${query}" in "${category}"`);
  
  // Performance testing
  const transformTimes = [];
  let niches = [];
  
  // Run multiple iterations for performance statistics
  for (let i = 0; i < PERFORMANCE_TEST_ITERATIONS; i++) {
    const startTime = performance.now();
    niches = getMockNichesForCategory(query, category);
    const endTime = performance.now();
    transformTimes.push(endTime - startTime);
  }
  
  // Get statistics
  const timeStats = calculateStats(transformTimes);
  
  // Prepare niche data for relevance calculation
  const data = { niches: niches.map(name => ({ name })) };
  const params = { query, category };
  
  // Calculate relevance metrics
  const metrics = calculateRelevanceMetrics(data, params);
  
  // Print results
  console.log(`Generated niches: ${niches.join(', ')}`);
  console.log(`Relevance score: ${formatPercentage(metrics.averageRelevanceScore)}`);
  console.log(`Relevant niches: ${metrics.relevantNicheCount}/${niches.length} (${formatPercentage(metrics.relevantNichePercentage)})`);
  console.log(`Match types: Exact: ${metrics.matchTypes.exact}, Partial: ${metrics.matchTypes.partial}, Category: ${metrics.matchTypes.category}, None: ${metrics.matchTypes.none}`);
  
  // Performance metrics
  console.log(`\nPerformance metrics (${PERFORMANCE_TEST_ITERATIONS} iterations):`);
  console.log(`- Average transform time: ${formatMs(timeStats.avg)}`);
  console.log(`- Min transform time: ${formatMs(timeStats.min)}`);
  console.log(`- Max transform time: ${formatMs(timeStats.max)}`);
  console.log(`- P95 transform time: ${formatMs(timeStats.p95)}`);
  
  if (printDetails) {
    // Individual relevance scores
    console.log('\nIndividual niche relevance scores:');
    niches.forEach(name => {
      let scoreDetails = '';
      if (query && query.trim()) {
        const similarity = stringSimilarity(name, query);
        const matchType = similarity >= SIMILARITY_THRESHOLD ? 'MATCH' : 'BELOW_THRESHOLD';
        const bonusInfo = name.toLowerCase().includes(query.toLowerCase()) ? ' +substring' : '';
        scoreDetails = `similarity: ${formatPercentage(similarity)} [${matchType}${bonusInfo}]`;
      }
      if (category && category !== 'All') {
        const catMatch = name.toLowerCase().includes(category.toLowerCase());
        if (catMatch) {
          scoreDetails += (scoreDetails ? ' | ' : '') + 'category match';
        }
      }
      console.log(`- ${name}: ${scoreDetails || 'N/A'}`);
    });
  }
  
  return {
    niches,
    metrics,
    timeStats
  };
}

// Run main test cases
console.log('🧪 RUNNING MANUAL TEST CASES FOR PHASE 0 🧪');
console.log('==========================================');

console.log('\n🔍 STANDARD TEST CASES:');

// 1. "mobile" in "Gaming" category
const mobileGamingResults = checkRelevance('mobile', 'Gaming');

// 2. "tutorial" in "Education" category
const tutorialEduResults = checkRelevance('tutorial', 'Education');

// 3. "makeup" in "Howto & Style" category
const makeupStyleResults = checkRelevance('makeup', 'Howto & Style');

// 4. Empty query with category only
const emptyQueryResults = checkRelevance('', 'Gaming');

// 5. Query with no category
const noCategoryResults = checkRelevance('mobile', 'All');

console.log('\n🔍 EDGE CASES:');

// Very short query (1-2 characters)
const shortQueryResults = checkRelevance('a', 'Gaming', false);

// Very long query (50+ characters)
const longQuery = 'a'.repeat(60);
const longQueryResults = checkRelevance(longQuery, 'Gaming', false);

// Special characters in query
const specialQueryResults = checkRelevance('gaming!@#$%^&*()_+', 'Gaming', false);

// Non-existent category
const nonExistentCategoryResults = checkRelevance('gaming', 'NonExistentCategory', false);

// Summary
console.log('\n📊 PERFORMANCE SUMMARY 📊');
console.log('========================');

// Collect all the transform times
const allTimes = [
  mobileGamingResults.timeStats.avg,
  mobileGamingResults.timeStats.min,
  mobileGamingResults.timeStats.max,
  tutorialEduResults.timeStats.avg,
  tutorialEduResults.timeStats.min,
  tutorialEduResults.timeStats.max,
  makeupStyleResults.timeStats.avg,
  makeupStyleResults.timeStats.min,
  makeupStyleResults.timeStats.max,
  emptyQueryResults.timeStats.avg,
  emptyQueryResults.timeStats.min,
  emptyQueryResults.timeStats.max,
  noCategoryResults.timeStats.avg,
  noCategoryResults.timeStats.min,
  noCategoryResults.timeStats.max,
  shortQueryResults.timeStats.avg,
  shortQueryResults.timeStats.min,
  shortQueryResults.timeStats.max,
  longQueryResults.timeStats.avg,
  longQueryResults.timeStats.min,
  longQueryResults.timeStats.max,
  specialQueryResults.timeStats.avg,
  specialQueryResults.timeStats.min,
  specialQueryResults.timeStats.max,
  nonExistentCategoryResults.timeStats.avg,
  nonExistentCategoryResults.timeStats.min,
  nonExistentCategoryResults.timeStats.max
].filter(t => typeof t === 'number');

const overallStats = calculateStats(allTimes);

console.log(`Overall transform time (across all test cases):`);
console.log(`- Average: ${formatMs(overallStats.avg)}`);
console.log(`- Minimum: ${formatMs(overallStats.min)}`);
console.log(`- Maximum: ${formatMs(overallStats.max)}`);
console.log(`- P95: ${formatMs(overallStats.p95)}`);

console.log('\n📊 RELEVANCE SUMMARY 📊');
console.log('=====================');

// Function to calculate average relevance percentage
function avgRelevancePercentage(results) {
  return results.metrics.relevantNichePercentage * 100;
}

const standardTestRelevance = [
  mobileGamingResults, 
  tutorialEduResults, 
  makeupStyleResults, 
  emptyQueryResults, 
  noCategoryResults
].map(avgRelevancePercentage);

const standardAvgRelevance = standardTestRelevance.reduce((sum, val) => sum + val, 0) / standardTestRelevance.length;

console.log(`Standard test cases average relevance: ${standardAvgRelevance.toFixed(1)}%`);
console.log(`Edge cases average relevance: ${(
  [shortQueryResults, longQueryResults, specialQueryResults, nonExistentCategoryResults]
    .map(avgRelevancePercentage)
    .reduce((sum, val) => sum + val, 0) / 4
).toFixed(1)}%`);

// Performance requirement check
console.log('\n✅ REQUIREMENTS VALIDATION');
console.log('========================');

console.log(`Transformation time requirement (<100ms): ${overallStats.avg < 100 ? 'PASS ✓' : 'FAIL ✗'} (avg: ${formatMs(overallStats.avg)})`);

// Check if we have at least 5 relevant niches for our key test cases
const relevantRequirement = 
  mobileGamingResults.metrics.relevantNicheCount >= 5 &&
  tutorialEduResults.metrics.relevantNicheCount >= 5 &&
  makeupStyleResults.metrics.relevantNicheCount >= 5;

console.log(`Relevance requirement (≥5 relevant niches): ${relevantRequirement ? 'PASS ✓' : 'FAIL ✗'} (${mobileGamingResults.metrics.relevantNicheCount}, ${tutorialEduResults.metrics.relevantNicheCount}, ${makeupStyleResults.metrics.relevantNicheCount})`);

const successfulImplementation = 
  overallStats.avg < 100 && 
  relevantRequirement &&
  standardAvgRelevance >= 80;

console.log(`\nOverall Phase 0 implementation: ${successfulImplementation ? 'PASS ✓' : 'FAIL ✗'}`);

if (successfulImplementation) {
  console.log('\n🎉 All requirements for Phase 0 have been met!');
} else {
  console.error('\n❌ Some requirements for Phase 0 have not been met. See details above.');
}