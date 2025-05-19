/**
 * YouTube API and Workflow Validation Test
 *
 * This script tests:
 * 1. Connection to the Social Intelligence Agent
 * 2. Niche-Scout API functionality
 * 3. Seed-to-Blueprint API functionality
 */

const axios = require('axios');
require('dotenv').config();

// Configuration
const MISSION_CONTROL_URL = 'http://localhost:3007';
const SOCIAL_INTEL_HOST = process.env.SOCIAL_INTEL_HOST || 'http://localhost';
const SOCIAL_INTEL_PORT = process.env.SOCIAL_INTEL_PORT || 9000;
const SOCIAL_INTEL_URL = `${SOCIAL_INTEL_HOST}:${SOCIAL_INTEL_PORT}`;

// Test cases
const NICHE_SCOUT_TEST_CASES = [
  {
    name: 'Basic Gaming Query',
    params: {
      query: 'gaming',
      category: 'Gaming'
    }
  },
  {
    name: 'Education Query with Demographics',
    params: {
      query: 'education',
      category: 'Education',
      demographics: '18-24'
    }
  },
  {
    name: 'Specific Subcategory',
    params: {
      query: 'mobile',
      category: 'Gaming',
      subcategories: ['Mobile Gaming']
    }
  }
];

const SEED_TO_BLUEPRINT_TEST_CASES = [
  {
    name: 'YouTube Video URL',
    params: {
      input_type: 'video',
      video_url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'
    }
  },
  {
    name: 'Niche Input',
    params: {
      input_type: 'niche',
      niche_category: 'Education',
      niche_subcategory: 'tutorials'
    }
  }
];

// Test functions
async function testSocialIntelConnection() {
  console.log(`\n📡 Testing connection to Social Intelligence Agent at ${SOCIAL_INTEL_URL}`);
  try {
    // Use the /status endpoint since we know it exists
    const response = await axios.get(`${SOCIAL_INTEL_URL}/status`, { timeout: 5000 });
    console.log('✅ Connection successful!');
    console.log('Response:', JSON.stringify(response.data, null, 2));
    return true;
  } catch (error) {
    console.error('❌ Connection failed:', error.message);
    return false;
  }
}

async function testDirectAPIs() {
  console.log('\n📡 Testing direct endpoints on Social Intelligence Agent');
  try {
    // Test if specific API endpoints exist
    const endpoints = [
      '/api/youtube/niche-scout',
      '/api/youtube/blueprint'
    ];

    for (const endpoint of endpoints) {
      try {
        // Just checking if the endpoint exists with an OPTIONS request
        const response = await axios.options(`${SOCIAL_INTEL_URL}${endpoint}`);
        console.log(`✅ Endpoint ${endpoint} exists`);
      } catch (error) {
        if (error.response && error.response.status !== 404) {
          console.log(`✅ Endpoint ${endpoint} exists but returned error ${error.response.status}`);
        } else {
          console.error(`❌ Endpoint ${endpoint} does not exist:`, error.message);
        }
      }
    }

    return true;
  } catch (error) {
    console.error('❌ Error testing direct APIs:', error.message);
    return false;
  }
}

async function testNicheScoutWorkflow() {
  console.log('\n📡 Testing Niche-Scout workflow through Mission Control');

  const results = [];

  for (const testCase of NICHE_SCOUT_TEST_CASES) {
    console.log(`\nRunning test case: ${testCase.name}`);
    console.log('Parameters:', JSON.stringify(testCase.params, null, 2));

    try {
      const response = await axios.post(`${MISSION_CONTROL_URL}/api/workflows/niche-scout`, testCase.params, {
        headers: {
          'Content-Type': 'application/json'
        }
      });

      console.log('✅ API call successful');

      // Check if the response has the expected structure
      let valid = false;
      if (response.data) {
        if (response.data.result && response.data.result.trending_niches) {
          valid = true;
          console.log('✓ Response has expected mock data structure');
        } else if (response.data.niches) {
          valid = true;
          console.log('✓ Response has expected API data structure');
        }
      }

      results.push({
        name: testCase.name,
        success: true,
        validStructure: valid,
        mockData: !!response.data._mock,
        data: response.data
      });
    } catch (error) {
      console.error('❌ API call failed:', error.message);
      results.push({
        name: testCase.name,
        success: false,
        error: error.message
      });
    }
  }

  return results;
}

async function testSeedToBlueprintWorkflow() {
  console.log('\n📡 Testing Seed-to-Blueprint workflow through Mission Control');

  const results = [];

  for (const testCase of SEED_TO_BLUEPRINT_TEST_CASES) {
    console.log(`\nRunning test case: ${testCase.name}`);
    console.log('Parameters:', JSON.stringify(testCase.params, null, 2));

    try {
      const response = await axios.post(`${MISSION_CONTROL_URL}/api/workflows/seed-to-blueprint`, testCase.params, {
        headers: {
          'Content-Type': 'application/json'
        }
      });

      console.log('✅ API call successful');

      // Check if the response has the expected structure
      let valid = false;
      if (response.data && response.data.result && response.data.result.channel_blueprint) {
        valid = true;
        console.log('✓ Response has expected structure');
      }

      results.push({
        name: testCase.name,
        success: true,
        validStructure: valid,
        mockData: !!response.data._mock,
        data: response.data
      });
    } catch (error) {
      console.error('❌ API call failed:', error.message);
      results.push({
        name: testCase.name,
        success: false,
        error: error.message
      });
    }
  }

  return results;
}

// Run all tests
async function runTests() {
  console.log('🧪 STARTING YOUTUBE API AND WORKFLOW VALIDATION TESTS 🧪');
  console.log('======================================================');

  // Test connection to Social Intelligence Agent
  const connectionOk = await testSocialIntelConnection();

  // Test direct APIs if connection is successful
  let directApisOk = false;
  if (connectionOk) {
    directApisOk = await testDirectAPIs();
  }

  // Test Niche-Scout workflow
  const nicheScoutResults = await testNicheScoutWorkflow();

  // Test Seed-to-Blueprint workflow
  const seedToBlueprintResults = await testSeedToBlueprintWorkflow();

  // Print summary
  console.log('\n📊 TEST RESULTS SUMMARY 📊');
  console.log('=========================');
  console.log(`Social Intelligence Connection: ${connectionOk ? '✅ OK' : '❌ Failed'}`);
  console.log(`Direct API Test: ${directApisOk ? '✅ OK' : '❌ Failed'}`);

  console.log('\nNiche-Scout Tests:');
  nicheScoutResults.forEach(result => {
    console.log(`- ${result.name}: ${result.success ? '✅ Passed' : '❌ Failed'}`);
    if (result.success) {
      console.log(`  - Valid Structure: ${result.validStructure ? '✓ Yes' : '✗ No'}`);
      console.log(`  - Using Mock Data: ${result.mockData ? '⚠️ Yes' : '✓ No'}`);
    }
  });

  console.log('\nSeed-to-Blueprint Tests:');
  seedToBlueprintResults.forEach(result => {
    console.log(`- ${result.name}: ${result.success ? '✅ Passed' : '❌ Failed'}`);
    if (result.success) {
      console.log(`  - Valid Structure: ${result.validStructure ? '✓ Yes' : '✗ No'}`);
      console.log(`  - Using Mock Data: ${result.mockData ? '⚠️ Yes' : '✓ No'}`);
    }
  });

  // Analyze real vs mock data usage
  const nicheScoutMockCount = nicheScoutResults.filter(r => r.mockData).length;
  const seedToBlueprintMockCount = seedToBlueprintResults.filter(r => r.mockData).length;

  console.log('\n🔍 DATA SOURCE ANALYSIS 🔍');
  console.log('========================');
  console.log(`Niche-Scout: ${nicheScoutMockCount}/${nicheScoutResults.length} tests used mock data`);
  console.log(`Seed-to-Blueprint: ${seedToBlueprintMockCount}/${seedToBlueprintResults.length} tests used mock data`);

  if (nicheScoutMockCount === 0 && seedToBlueprintMockCount === 0) {
    console.log('\n🎉 All tests used real API data!');
  } else if (nicheScoutMockCount === 0) {
    console.log('\n🔧 Niche-Scout is using real API data, but Seed-to-Blueprint is using mock data.');
  } else if (seedToBlueprintMockCount === 0) {
    console.log('\n🔧 Seed-to-Blueprint is using real API data, but Niche-Scout is using mock data.');
  } else {
    console.log('\n⚠️ Both workflows are using mock data.');
  }

  // Provide recommendations based on test results
  console.log('\n📋 RECOMMENDATIONS 📋');
  console.log('===================');

  if (!connectionOk) {
    console.log('1. Check if the Social Intelligence Agent is running');
    console.log('2. Verify the host and port in .env file');
    console.log('3. Ensure network connectivity between services');
  } else if (!directApisOk) {
    console.log('1. The Social Intelligence Agent is running but expected APIs are not available');
    console.log('2. Check if the agent exposes the required endpoints');
    console.log('3. Verify API paths in the integration script');
  } else if (nicheScoutMockCount > 0 || seedToBlueprintMockCount > 0) {
    console.log('1. Some workflow APIs are using mock data');
    console.log('2. Check API endpoint paths and payload formats');
    console.log('3. Verify that the Social Intelligence Agent implements all required endpoints');
  } else {
    console.log('✅ All systems functioning properly! No action needed.');
  }
}

// Run the tests
runTests();
