const axios = require('axios');

// Configuration
const API_BASE_URL = 'http://localhost:3007';
const TESTS = {
  health: true,
  agentStatus: true,
  nicheScout: true,
  seedToBlueprint: true
};

// Test functions
async function testHealth() {
  console.log('\n📡 Testing health endpoint...');
  try {
    const response = await axios.get(`${API_BASE_URL}/api/health`);
    console.log('✅ Health check response:', JSON.stringify(response.data, null, 2));
    return true;
  } catch (error) {
    console.error('❌ Health check failed:', error.message);
    return false;
  }
}

async function testAgentStatus() {
  console.log('\n📡 Testing agent status endpoint...');
  try {
    const response = await axios.get(`${API_BASE_URL}/api/agents/status`);
    console.log('✅ Agent status response:', JSON.stringify(response.data, null, 2));
    return true;
  } catch (error) {
    console.error('❌ Agent status check failed:', error.message);
    return false;
  }
}

async function testNicheScout() {
  console.log('\n📡 Testing Niche-Scout workflow...');
  try {
    const response = await axios.post(`${API_BASE_URL}/api/workflows/niche-scout`, {
      category: 'gaming',
      subcategory: 'mobile-gaming'
    });
    console.log('✅ Niche-Scout response:', JSON.stringify(response.data, null, 2));
    return true;
  } catch (error) {
    console.error('❌ Niche-Scout test failed:', error.message);
    return false;
  }
}

async function testSeedToBlueprint() {
  console.log('\n📡 Testing Seed-to-Blueprint workflow...');
  try {
    const response = await axios.post(`${API_BASE_URL}/api/workflows/seed-to-blueprint`, {
      input_type: 'video',
      video_url: 'https://www.youtube.com/watch?v=example'
    });
    console.log('✅ Seed-to-Blueprint response:', JSON.stringify(response.data, null, 2));
    return true;
  } catch (error) {
    console.error('❌ Seed-to-Blueprint test failed:', error.message);
    return false;
  }
}

// Run all enabled tests
async function runTests() {
  console.log('🧪 STARTING INTEGRATION TESTS 🧪');
  console.log('===============================');

  const results = {};

  if (TESTS.health) results.health = await testHealth();
  if (TESTS.agentStatus) results.agentStatus = await testAgentStatus();
  if (TESTS.nicheScout) results.nicheScout = await testNicheScout();
  if (TESTS.seedToBlueprint) results.seedToBlueprint = await testSeedToBlueprint();

  // Print summary
  console.log('\n📊 TEST RESULTS SUMMARY 📊');
  console.log('=========================');
  let passed = 0;
  let failed = 0;

  Object.entries(results).forEach(([test, success]) => {
    console.log(`${success ? '✅' : '❌'} ${test}: ${success ? 'PASSED' : 'FAILED'}`);
    success ? passed++ : failed++;
  });

  console.log(`\n${passed} tests passed, ${failed} tests failed`);

  if (failed > 0) {
    console.log('\n⚠️ Some tests failed. Please check the logs above for details.');
    process.exit(1);
  } else {
    console.log('\n🎉 All tests passed successfully!');
    process.exit(0);
  }
}

// Run the tests
runTests();
