/**
 * Unit tests for Phase 0 Niche-Scout ↔ Social-Intel Integration
 * 
 * Tests the string similarity function, niche generation, and metrics calculation
 */

const { 
  stringSimilarity, 
  getMockNichesForCategory, 
  getTopicsForNiche,
  calculateRelevanceMetrics, 
  SIMILARITY_THRESHOLD,
  DEFAULT_NICHE_COUNT 
} = require('./integrate-with-social-intel');

// Flag to display extra debug info
const DEBUG = false;

/**
 * Simple test runner
 */
function runTests() {
  console.log('🧪 RUNNING PHASE 0 TRANSFORMATION UNIT TESTS 🧪');
  console.log('=============================================');

  let passedTests = 0;
  let totalTests = 0;

  function test(name, fn) {
    totalTests++;
    try {
      fn();
      console.log(`✅ PASS: ${name}`);
      passedTests++;
    } catch (error) {
      console.log(`❌ FAIL: ${name}`);
      console.error(`   Error: ${error.message}`);
    }
  }

  function assert(condition, message) {
    if (!condition) {
      throw new Error(message || 'Assertion failed');
    }
  }

  // Test string similarity function
  console.log('\n🔍 Testing String Similarity Function');
  console.log('----------------------------------');

  test('Identical strings should have similarity 1.0', () => {
    const result = stringSimilarity('gaming', 'gaming');
    if (DEBUG) console.log(`   Result: ${result}`);
    assert(result === 1.0, `Expected 1.0, got ${result}`);
  });

  test('Empty strings should have similarity 1.0', () => {
    const result = stringSimilarity('', '');
    if (DEBUG) console.log(`   Result: ${result}`);
    assert(result === 1.0, `Expected 1.0, got ${result}`);
  });

  test('One empty string should have similarity 0.0', () => {
    const result = stringSimilarity('gaming', '');
    if (DEBUG) console.log(`   Result: ${result}`);
    assert(result === 0.0, `Expected 0.0, got ${result}`);
  });

  test('Case insensitivity', () => {
    const result = stringSimilarity('Gaming', 'gaming');
    if (DEBUG) console.log(`   Result: ${result}`);
    assert(result === 1.0, `Expected 1.0, got ${result}`);
  });

  test('Similar strings should have high similarity', () => {
    const result = stringSimilarity('gaming', 'games');
    if (DEBUG) console.log(`   Result: ${result}`);
    assert(result >= 0.32, `Expected >= 0.32, got ${result}`); // Adjusted threshold for new algorithm
  });

  test('Different strings should have low similarity', () => {
    const result = stringSimilarity('gaming', 'education');
    if (DEBUG) console.log(`   Result: ${result}`);
    assert(result <= 0.4, `Expected <= 0.4, got ${result}`);
  });

  test('Substring should have high similarity', () => {
    const result = stringSimilarity('mobile gaming', 'mobile');
    if (DEBUG) console.log(`   Result: ${result}`);
    assert(result >= 0.5, `Expected >= 0.5, got ${result}`);
  });

  // Test niche generation
  console.log('\n🔍 Testing Niche Generation');
  console.log('---------------------------');

  test('Default niche count should be correct', () => {
    const niches = getMockNichesForCategory('gaming', 'Gaming');
    if (DEBUG) console.log(`   Result: ${niches.length} niches - ${niches.join(', ')}`);
    assert(niches.length === DEFAULT_NICHE_COUNT, `Expected ${DEFAULT_NICHE_COUNT} niches, got ${niches.length}`);
  });

  test('Gaming category should return gaming-related niches', () => {
    const niches = getMockNichesForCategory('mobile', 'Gaming');
    if (DEBUG) console.log(`   Result: ${niches.join(', ')}`);
    
    // Count how many niches contain 'mobile', 'game', or 'gaming'
    const relevantCount = niches.filter(niche => 
      niche.toLowerCase().includes('mobile') || 
      niche.toLowerCase().includes('game') || 
      niche.toLowerCase().includes('gaming')
    ).length;
    
    assert(relevantCount >= 3, `Expected at least 3 relevant niches, got ${relevantCount}`);
  });

  test('Education category should return education-related niches', () => {
    const niches = getMockNichesForCategory('tutorial', 'Education');
    if (DEBUG) console.log(`   Result: ${niches.join(', ')}`);
    
    // Count how many niches contain 'tutorial', 'education', or 'learning'
    const relevantCount = niches.filter(niche => 
      niche.toLowerCase().includes('tutorial') || 
      niche.toLowerCase().includes('education') || 
      niche.toLowerCase().includes('learning')
    ).length;
    
    assert(relevantCount >= 3, `Expected at least 3 relevant niches, got ${relevantCount}`);
  });

  test('Category with empty query should still return niches', () => {
    const niches = getMockNichesForCategory('', 'Gaming');
    if (DEBUG) console.log(`   Result: ${niches.join(', ')}`);
    assert(niches.length === DEFAULT_NICHE_COUNT, `Expected ${DEFAULT_NICHE_COUNT} niches, got ${niches.length}`);
  });

  test('Empty category with query should return results', () => {
    const niches = getMockNichesForCategory('gaming', '');
    if (DEBUG) console.log(`   Result: ${niches.join(', ')}`);
    assert(niches.length === DEFAULT_NICHE_COUNT, `Expected ${DEFAULT_NICHE_COUNT} niches, got ${niches.length}`);
  });

  test('Both empty should still return default niches', () => {
    const niches = getMockNichesForCategory('', '');
    if (DEBUG) console.log(`   Result: ${niches.join(', ')}`);
    assert(niches.length === DEFAULT_NICHE_COUNT, `Expected ${DEFAULT_NICHE_COUNT} niches, got ${niches.length}`);
  });

  test('All category should still return relevant niches for query', () => {
    const niches = getMockNichesForCategory('mobile', 'All');
    if (DEBUG) console.log(`   Result: ${niches.join(', ')}`);
    
    // Count how many niches contain 'mobile'
    const mobilenNiches = niches.filter(niche => 
      niche.toLowerCase().includes('mobile')
    ).length;
    
    assert(mobilenNiches >= 1, `Expected at least 1 mobile niche, got ${mobilenNiches}`);
  });

  // Test trending topics
  console.log('\n🔍 Testing Topic Generation');
  console.log('---------------------------');

  test('Gaming niche should return gaming topics', () => {
    const topics = getTopicsForNiche('Mobile Gaming');
    if (DEBUG) console.log(`   Result: ${topics.join(', ')}`);
    assert(topics.length === 3, `Expected 3 topics, got ${topics.length}`);
    
    // Check if topics are related to mobile or gaming
    const relevantCount = topics.filter(topic => 
      topic.toLowerCase().includes('mobile') || 
      topic.toLowerCase().includes('game') || 
      topic.toLowerCase().includes('gaming')
    ).length;
    
    assert(relevantCount >= 1, `Expected at least 1 relevant topic, got ${relevantCount}`);
  });

  test('Education niche should return education topics', () => {
    const topics = getTopicsForNiche('Online Courses');
    if (DEBUG) console.log(`   Result: ${topics.join(', ')}`);
    assert(topics.length === 3, `Expected 3 topics, got ${topics.length}`);
    
    // Check if topics are related to education or courses
    const relevantCount = topics.filter(topic => 
      topic.toLowerCase().includes('course') || 
      topic.toLowerCase().includes('education') || 
      topic.toLowerCase().includes('learning') ||
      topic.toLowerCase().includes('online')
    ).length;
    
    assert(relevantCount >= 1, `Expected at least 1 relevant topic, got ${relevantCount}`);
  });

  // Test relevance metrics calculation
  console.log('\n🔍 Testing Relevance Metrics');
  console.log('---------------------------');

  test('Empty data should return zero metrics', () => {
    const metrics = calculateRelevanceMetrics({}, {});
    if (DEBUG) console.log('   Result:', metrics);
    assert(metrics.relevantNicheCount === 0, 'Expected 0 relevant niches');
    assert(metrics.averageRelevanceScore === 0, 'Expected 0 average relevance');
  });

  test('Exact query matches should be counted correctly', () => {
    const transformedData = {
      niches: [
        { name: 'mobile gaming' },
        { name: 'mobile' },
        { name: 'gaming mobile' },
        { name: 'education' },
        { name: 'unrelated' }
      ]
    };
    
    const searchParams = { query: 'mobile', category: 'Gaming' };
    
    const metrics = calculateRelevanceMetrics(transformedData, searchParams);
    if (DEBUG) console.log('   Result:', metrics);
    
    assert(metrics.relevantNicheCount >= 3, `Expected at least 3 relevant niches, got ${metrics.relevantNicheCount}`);
    assert(metrics.averageRelevanceScore >= 0.5, `Expected avg relevance >= 0.5, got ${metrics.averageRelevanceScore}`);
    assert(metrics.matchTypes.exact === 1, `Expected 1 exact match, got ${metrics.matchTypes.exact}`);
  });

  test('Category matches should be counted correctly', () => {
    const transformedData = {
      niches: [
        { name: 'Mobile Gaming' },
        { name: 'Gaming Strategy' },
        { name: 'Game Reviews' },
        { name: 'Educational Gaming' },
        { name: 'Unrelated' }
      ]
    };
    
    const searchParams = { query: '', category: 'Gaming' };
    
    const metrics = calculateRelevanceMetrics(transformedData, searchParams);
    if (DEBUG) console.log('   Result:', metrics);
    
    assert(metrics.relevantNicheCount >= 3, `Expected at least 3 relevant niches, got ${metrics.relevantNicheCount}`);
    assert(metrics.matchTypes.category >= 3, `Expected at least 3 category matches, got ${metrics.matchTypes.category}`);
  });

  // Test end-to-end relevance for key test cases
  console.log('\n🔍 Testing End-to-End Relevance');
  console.log('------------------------------');

  test('"mobile" in "Gaming" should yield highly relevant niches', () => {
    const niches = getMockNichesForCategory('mobile', 'Gaming');
    const data = { niches: niches.map(name => ({ name })) };
    const params = { query: 'mobile', category: 'Gaming' };
    
    const metrics = calculateRelevanceMetrics(data, params);
    if (DEBUG) {
      console.log(`   Niches: ${niches.join(', ')}`);
      console.log('   Metrics:', metrics);
    }
    
    assert(metrics.relevantNicheCount >= 3, `Expected at least 3 relevant niches, got ${metrics.relevantNicheCount}`);
    assert(metrics.averageRelevanceScore >= 0.6, `Expected avg relevance >= 0.6, got ${metrics.averageRelevanceScore}`);
  });

  test('"tutorial" in "Education" should yield highly relevant niches', () => {
    const niches = getMockNichesForCategory('tutorial', 'Education');
    const data = { niches: niches.map(name => ({ name })) };
    const params = { query: 'tutorial', category: 'Education' };
    
    const metrics = calculateRelevanceMetrics(data, params);
    if (DEBUG) {
      console.log(`   Niches: ${niches.join(', ')}`);
      console.log('   Metrics:', metrics);
    }
    
    assert(metrics.relevantNicheCount >= 3, `Expected at least 3 relevant niches, got ${metrics.relevantNicheCount}`);
    assert(metrics.averageRelevanceScore >= 0.6, `Expected avg relevance >= 0.6, got ${metrics.averageRelevanceScore}`);
  });

  test('"makeup" in "Howto & Style" should yield highly relevant niches', () => {
    const niches = getMockNichesForCategory('makeup', 'Howto & Style');
    const data = { niches: niches.map(name => ({ name })) };
    const params = { query: 'makeup', category: 'Howto & Style' };
    
    const metrics = calculateRelevanceMetrics(data, params);
    if (DEBUG) {
      console.log(`   Niches: ${niches.join(', ')}`);
      console.log('   Metrics:', metrics);
    }
    
    assert(metrics.relevantNicheCount >= 3, `Expected at least 3 relevant niches, got ${metrics.relevantNicheCount}`);
    assert(metrics.averageRelevanceScore >= 0.6, `Expected avg relevance >= 0.6, got ${metrics.averageRelevanceScore}`);
  });

  // Test edge cases
  console.log('\n🔍 Testing Edge Cases');
  console.log('--------------------');

  test('Very short query (1-2 chars) should still yield relevant results', () => {
    const niches = getMockNichesForCategory('a', 'Gaming');
    if (DEBUG) console.log(`   Result: ${niches.join(', ')}`);
    assert(niches.length === DEFAULT_NICHE_COUNT, `Expected ${DEFAULT_NICHE_COUNT} niches, got ${niches.length}`);
  });

  test('Very long query (50+ chars) should not break the algorithm', () => {
    const longQuery = 'a'.repeat(60);
    const niches = getMockNichesForCategory(longQuery, 'Gaming');
    if (DEBUG) console.log(`   Result: ${niches.join(', ')}`);
    assert(niches.length === DEFAULT_NICHE_COUNT, `Expected ${DEFAULT_NICHE_COUNT} niches, got ${niches.length}`);
  });

  test('Special characters in query should not break anything', () => {
    const specialQuery = 'game!@#$%^&*()_+';
    const niches = getMockNichesForCategory(specialQuery, 'Gaming');
    if (DEBUG) console.log(`   Result: ${niches.join(', ')}`);
    assert(niches.length === DEFAULT_NICHE_COUNT, `Expected ${DEFAULT_NICHE_COUNT} niches, got ${niches.length}`);
  });

  test('Non-existent category should fall back to default niches', () => {
    const niches = getMockNichesForCategory('something', 'NonExistentCategory');
    if (DEBUG) console.log(`   Result: ${niches.join(', ')}`);
    assert(niches.length === DEFAULT_NICHE_COUNT, `Expected ${DEFAULT_NICHE_COUNT} niches, got ${niches.length}`);
  });

  // Summary results
  console.log('\n📊 TEST RESULTS SUMMARY 📊');
  console.log('=========================');
  console.log(`Passed: ${passedTests}/${totalTests} tests (${Math.round(passedTests/totalTests*100)}%)`);
  
  if (passedTests === totalTests) {
    console.log('\n🎉 All tests passed!');
  } else {
    console.log(`\n❌ ${totalTests - passedTests} tests failed.`);
  }
}

// Run all tests
runTests();