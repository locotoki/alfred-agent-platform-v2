const axios = require('axios');
require('dotenv').config();

// Configuration
const SOCIAL_INTEL_HOST = process.env.SOCIAL_INTEL_HOST || 'http://localhost';
const SOCIAL_INTEL_PORT = process.env.SOCIAL_INTEL_PORT || 9000;
const API_BASE_URL = `${SOCIAL_INTEL_HOST}:${SOCIAL_INTEL_PORT}`;

async function testSocialIntelHealth() {
  console.log(`\n📡 Testing Social Intelligence health at ${API_BASE_URL}/status...`);
  try {
    const response = await axios.get(`${API_BASE_URL}/status`, { timeout: 5000 });
    console.log('✅ Response:', JSON.stringify(response.data, null, 2));
    return true;
  } catch (error) {
    console.error('❌ Request failed:', error.message);
    return false;
  }
}

// Test available endpoints
async function testAvailableEndpoints() {
  console.log('\n📡 Testing API documentation availability...');
  try {
    const response = await axios.get(`${API_BASE_URL}/docs`, { timeout: 5000 });
    console.log('✅ Docs endpoint is available');
    return true;
  } catch (error) {
    console.error('❌ Docs endpoint check failed:', error.message);
    return false;
  }
}

// Run all tests
async function runTests() {
  console.log('🧪 TESTING DIRECT CONNECTION TO SOCIAL INTELLIGENCE AGENT 🧪');
  console.log('==========================================================');
  
  const healthStatus = await testSocialIntelHealth();
  const docsStatus = await testAvailableEndpoints();
  
  console.log('\n📊 RESULTS 📊');
  console.log('============');
  console.log(`Health endpoint: ${healthStatus ? '✅ Available' : '❌ Not available'}`);
  console.log(`Docs endpoint: ${docsStatus ? '✅ Available' : '❌ Not available'}`);
  
  if (!healthStatus) {
    console.log('\n⚠️ Cannot reach Social Intelligence agent. Please check:');
    console.log('  1. Is the Social Intelligence agent running?');
    console.log('  2. Are the host and port correct in your .env file?');
    console.log('  3. Is there network connectivity between services?');
    console.log(`  4. Current base URL: ${API_BASE_URL}`);
  }
}

runTests();